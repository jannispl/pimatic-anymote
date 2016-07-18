# #my-plugin configuration options
# Declare your config option for your plugin here. 
module.exports = {
  title: "AnyMotePlugin config options"
  type: "object"
  properties:
    bleAddress:
      description: "BLE address of AnyMote Home device"
      type: "string"
}
