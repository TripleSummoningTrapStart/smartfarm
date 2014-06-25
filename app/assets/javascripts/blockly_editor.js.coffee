jQuery ->
  editor = $('#blockly-editor')
  if(editor.length > 0)
    url = editor.data('model-url')
    type = editor.data('model-type')

    # Resize editor to fit window
    editor.height($(window).height() - 120);
    $('#blockly-iopanel').height(editor.height());

    # Setup Blockly
    Blockly.JavaScript.addReservedWords('highlightBlock')
    Blockly.inject(document.getElementById('blockly-editor'), {
      path: '/assets/blockly/', 
      toolbox: document.getElementById('toolbox')
    })
    Blockly.Xml.domToWorkspace(
      Blockly.mainWorkspace, 
      document.getElementById('workspace')
    )

    # Add a saved/needs saving message
    msg = $('#message');
    Blockly.addChangeListener () ->
      msg.text("Changed...")
    callback = -> msg.text("")
    setTimeout callback, 100

    # Add a save button
    saveButton = $('button#save');
    saveButton.on 'click', () ->
      xml = Blockly.Xml.workspaceToDom(Blockly.mainWorkspace)
      xml.id = "workspace"
      xml.setAttribute("style", "display: none")
      xmlText = Blockly.Xml.domToText(xml);
      code = Blockly.JavaScript.workspaceToCode()
      data = {}
      data[type] = 
        workspace: xmlText
        code: code
      msg.text("Saving...")
      $.ajax url, 
        method: "PUT"
        #contentType: "JSON"
        data: data
        success: (response) ->
          msg.text(response)
        error: (jXHR, status, err) ->
          msg.text(err);

    # Add a getter and setter to the interpreter
    attrAccessor = (name, interpreter, scope) ->

      # getter
      wrapper = () ->
        num = $('#' + name).val()
        num = parseFloat(num)
        return interpreter.createPrimitive(num);
      interpreter.setProperty(scope, 'get_' + name, interpreter.createNativeFunction(wrapper))

      # setter
      wrapper = (num) ->
        num = if num then parseFloat(num) else 0
        return interpreter.createPrimitive($('#' + name).val(num));
      interpreter.setProperty(scope, 'set_' + name, interpreter.createNativeFunction(wrapper))

    # Set up the JS interpreter
    setupJavaScriptInterpreter = (interpreter, scope) ->

      # alert() function
      wrapper = (text) ->
        text = if text then text.toString() else ''
        return interpreter.createPrimitive(alert(text))
      interpreter.setProperty(scope, 'alert', interpreter.createNativeFunction(wrapper))

      # prompt() function
      wrapper = (text) ->
        text if text then text.toString() else ''
        return interpreter.createPrimitive(prompt(text))
      interpreter.setProperty(scope, 'prompt', interpreter.createNativeFunction(wrapper))

      # elapsed time
      wrapper = () ->
        num = $('#elapsed_time').val()
        num = parseInt(num)
        return interpreter.createPrimitive(num);
      interpreter.setProperty(scope, 'get_elapsed_time', interpreter.createNativeFunction(wrapper))

      # simulation attribute getters/setters
      attributes = ["latitude", "longitude"]
      attributes.forEach (name) ->
        attrAccessor(name, interpreter, scope)

      # weather attribute getters/setters
      attributes = ["rainfall", "snowfall", "average_temperature", "high_temperature", "low_temperature", "wind_speed", "wind_direction", "relative_humidity"]
      attributes.forEach (name) ->
        attrAccessor(name, interpreter, scope)

    interpreter = undefined
    nextStep = () ->
      if interpreter
        if !interpreter.step()
          interpreter = undefined

    stepButton = $('button#step')
    stepButton.on 'click', () ->
      if !interpreter
        interpreter = new Interpreter(Blockly.JavaScript.workspaceToCode(), setupJavaScriptInterpreter)
      nextStep()

    # Add a run button
    runButton = $('button#run')
    runButton.on 'click', () ->
      interpreter = new Interpreter(Blockly.JavaScript.workspaceToCode(), setupJavaScriptInterpreter)
      interpreter.run()

  