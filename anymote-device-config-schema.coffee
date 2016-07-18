module.exports = {
  title: "pimatic-ps4waker device config schemas"
  AnyMotePowerSwitch: {
    title: "AnyMote power switch"
    type: "object"
    properties:
      codeType:
        description: "Type of code to transmit (raw, pronto, nec)"
        type: "string"
      codeOn:
        description: "Code to transmit for ON state"
        type: "string"
      codeOff:
        description: "Code to transmit for OFF state"
        type: "string"
  },
  AnyMoteButtonsDevice: {
    title: "AnyMoteButtonsDevice config options"
    type: "object"
    properties:
      buttons:
        description: "Buttons to display"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
            text:
              type: "string"
            codeType:
              description: "Type of code to transmit (raw, pronto, nec)"
              type: "string"
            code:
              description: "Code to tramsit"
              type: "string"
  }
}