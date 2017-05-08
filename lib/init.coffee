path = null
helpers = null

module.exports =
  config:
    extraOptions:
      type: 'array'
      default: ['--lint-only', '--bbox-sys', '--bbox-unsup', '-DGLBL']
      description: 'Comma separated list of verilator options'
      items:
        type: 'string'
    executable:
      type: 'string'
      default: 'verilator'
      description: 'Path to verilator executable'

  activate: ->
    require('atom-package-deps').install('linter-verilator')

  provideLinter: ->
    provider =
      name: 'verilator'
      scope: 'file'
      lintsOnChange: false
      grammarScopes: ['source.verilog']
      lint: (editor) ->
        path ?= require 'path'
        helpers ?= require('atom-linter')
        regex = /%(Error|Warning)-?([^:]*): ((?:[A-Z]:)?[^:]+):([^:]+):(.+)/
        file = editor.getPath().replace(/\\/g,"/")
        dirname = path.dirname(file)

        args = ("#{arg}" for arg in atom.config.get('linter-verilator.extraOptions'))
        args = args.concat ['-I' + dirname,  file]
        return helpers.exec(atom.config.get('linter-verilator.executable'), args, {stream: 'stderr', allowEmptyStderr: true}).then (output) ->
          lines = output.split("\n")
          messages = []
          for line in lines
            if line.length == 0
              continue;

            #console.log(line)
            parts = line.match(regex)
            if !parts || parts.length != 6 || (file != parts[3].trim())
              #console.debug("Dropping line:", line)
            else
              message =
                location:
                  file: path.normalize(parts[3].trim()),
                  position: helpers.generateRange(editor, Math.min(editor.getLineCount(), parseInt(parts[4]))-1, 0)
                severity: parts[1].toLowerCase()
                excerpt: (if parts[2] then parts[2] + ": " else "") + parts[5].trim()

              #console.log(message)
              messages.push(message)

          return messages
