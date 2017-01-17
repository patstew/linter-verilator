{ CompositeDisposable } = require 'atom'
path = require 'path'

lint = (editor) ->
  helpers = require('atom-linter')
  regex = /%(Error|Warning)-?([^:]*): ((?:[A-Z]:)?[^:]+):([^:]+):(.+)/
  file = editor.getPath().replace(/\\/g,"/")
  dirname = path.dirname(file)

  args = ("#{arg}" for arg in atom.config.get('linter-verilator.extraOptions'))
  args = args.concat ['-I' + dirname,  file]
  helpers.exec(atom.config.get('linter-verilator.executable'), args, {stream: 'both'}).then (output) ->
    lines = output.stderr.split("\n")
    messages = []
    for line in lines
      if line.length == 0
        continue;

      console.log(line)
      parts = line.match(regex)
      if !parts || parts.length != 6
        console.debug("Dropping line:", line)
      else
        message =
          filePath: parts[3].trim()
          range: helpers.rangeFromLineNumber(editor, Math.min(editor.getLineCount(), parseInt(parts[4]))-1, 0)
          type: parts[1]
          text: (if parts[2] then parts[2] + ": " else "") + parts[5].trim()

        messages.push(message)

    return messages

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
      grammarScopes: ['source.verilog']
      scope: 'project'
      lintOnFly: false
      name: 'Verilator'
      lint: (editor) => lint(editor)
