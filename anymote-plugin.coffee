# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  #  

  AnyMote = require 'anymote'
  noble = require 'anymote/node_modules/noble'

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class AnyMotePlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      self = this

      constructAnymote = () ->
        self.anymote = new AnyMote(self.config.bleAddress, {
          autoReconnect: true
        })
        self.anymote.on('connect', () ->
          env.logger.info('AnyMote connection established')
        )

      if noble.state is 'poweredOn'
        constructAnymote()
      else
        stateChange = (state) ->
          if state is 'poweredOn'
            env.logger.info('BLE is now active!')
            constructAnymote()
          else
            noble.once('stateChange', stateChange)
        noble.once('stateChange', stateChange)

      deviceConfigDef = require("./anymote-device-config-schema")

      @framework.deviceManager.registerDeviceClass("AnyMotePowerSwitch", {
        configDef: deviceConfigDef.AnyMotePowerSwitch,
        createCallback: (config, lastState) => new AnyMotePowerSwitch(config, lastState, self)
      })
      @framework.deviceManager.registerDeviceClass("AnyMoteButtonsDevice", {
        configDef: deviceConfigDef.AnyMoteButtonsDevice,
        createCallback: (config) => new AnyMoteButtonsDevice(config, self)
      })

    transmitCode: (codeType, codeString, cb) ->
      return if not @anymote? or @anymote.state isnt 'connected' then cb(new Error('AnyMote is not connected yet'))

      code = null
      if codeType is 'raw'
        parts = codeString.split(',')
        code = {
          frequency: parseInt(parts[0]),
          pattern: parts.slice(1).map((v) => parseInt(v))
        }
      else if codeType is 'pronto'
        parsed = require('anymote/ircode').parsePronto(codeString)
        code = require('anymote/ircode').convertProntoToCode(parsed)
      else if codeType is 'nec'
        nec = parseInt(codeString, 16)
        code = require('anymote/ircode').convertNecToCode(nec)
      else
        return cb(new Error('Invalid code type: ' + codeType))

      return if not code then cb(new Error('Unable to parse code'))

      @anymote.playPattern(code.frequency, code.pattern, 0, (err) ->
        return if err then cb(err)

        cb(null)
      )

  class AnyMotePowerSwitch extends env.devices.PowerSwitch
    constructor: (@config, lastState, @plugin) ->
      @name = @config.name
      @id = @config.id
      @_state = lastState?.state?.value or off

      super()

    destroy: () ->
      super()

    changeStateTo: (state) ->
      self = this
      return new Promise((resolve, reject) ->
        actionCode = if state then self.config.codeOn else self.config.codeOff

        self.plugin.transmitCode(self.config.codeType.trim(), actionCode.trim(), (err) ->
          return if err then reject(err)

          self._setState(state)
          resolve()
        )
      )

  class AnyMoteButtonsDevice extends env.devices.ButtonsDevice
    constructor: (@config, @plugin) ->
      @name = @config.name
      @id = @config.id
      super(@config)

    destroy: () ->
      super()

    buttonPressed: (buttonId) ->
      self = this
      for b in @config.buttons
        if b.id is buttonId
          return new Promise((resolve, reject) ->
            self.plugin.transmitCode(b.codeType.trim(), b.code.trim(), (err) ->
              return if err then reject(err)

              self.emit('button', b.id)
              resolve()
            )
          )


  # ###Finally
  # Create a instance of my plugin
  myPlugin = new AnyMotePlugin
  # and return it to the framework.
  return myPlugin
