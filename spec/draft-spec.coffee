$ = require('./tarima')

describe 'known engines behavior', ->
  describe 'render()', ->
    it 'x.y.js should return as is', ->
      expect($('x.y.js', 'var x;').render()).toBe 'var x;'

    it 'x.es6.js should return transpiled ES6', ->
      expect($('x.es6.js', 'const x = "y"').render()).toContain 'var x = "y";'

    it 'x.js.hbs should return rendered Handlebars', ->
      expect($('x.js.hbs', 'x{{y}}').render(y: 'D')).toBe 'xD'

    it 'x.js.ejs should return rendered Embedded JavaScript', ->
      expect($('x.js.ejs', 'a<%=b%>').render(b: '!')).toBe 'a!'

    it 'x.js.coffee should return transpiled CoffeeScript', ->
      expect($('x.js.coffee', 'foo bar').render()).toContain 'foo(bar);'

    it 'x.js.ract should return a plain object (Ractive.js templating)', ->
      expect($('x.js.ract', '{{x}}').render()).toEqual { v: 3, t: [ { t: 2, r: 'x' } ] }

    it 'x.js.jade should return rendered Jade', ->
      expect($('x.js.jade', '|#[#{x}]').render(x: 'y')).toContain '<y></y>'

    it 'x.js.json should return parsed JSON', ->
      expect($('x.js.json', '{"x":"y"}').render()).toEqual { x: 'y' }

    it 'x.js.less should return rendered LESS', ->
      expect($('x.js.less', '*{&:_{x:@y}}').render(y: 'z')).toContain '''
        *:_ {
          x: z;
        }
      '''

    it 'x.js.md should return rendered Markdown', ->
      expect($('x.js.md', '# OK').render()).toMatch /<h1[^<>]*>OK<\/h1>/

    it 'x.json.ejs should return raw JSON from rendered EJS', ->
      expect($('x.json.ejs', '{"x":"<%=y%>"}').render(y: 'D')).toBe '{"x":"D"}'

  describe 'compile()', ->
    it 'x.js.hbs should return a pre-compiled Handlebars template', ->
      expect($('x.js.hbs', '{{#x}}y{{/x}}').compile(x: 1)).toContain 'Handlebars.template'

    it 'x.js.jade should return a pre-compiled Jade template', ->
      expect($('x.js.jade', 'x=y').compile(y: 'z')).toContain 'function template(locals)'

  describe 'mixed engines', ->
    describe 'x.litcoffee.hbs.ejs', ->
      tpl = '''
        # <%= title || 'Untitled' %>

        {{#option}}
            fun = ->
        {{/option}}{{^option}}
            class Klass; fun = new Klass
        {{/option}}
      '''

      view = $('x.litcoffee.hbs.ejs', tpl)

      it 'should return modified CoffeeScript calling render() and compile()', ->
        code = view.render(title: off)

        expect(code).toContain '# Untitled'
        expect(code).toContain 'class Klass'
        expect(code).not.toContain 'fun = ->'

        params =
          title: (new Date()).toString()

        expect(view.compile(params)).toBe view.render(params)

    describe 'x.js.ract.jade.ejs', ->
      tpl = '''
        h1 <%= title || 'Untitled' %>

        |{{#option}}
        div I am a div
        |{{/option}}{{^option}}
        span I am a span
        |{{/option}}
      '''

      view = $('x.js.ract.jade.ejs', tpl)

      it 'should return a plain object calling render()', ->
        expect(view.render(title: off).v).toBe 3

      it 'should return a Ractive.js template calling compile()', ->
        code = view.compile(title: 'OK')

        expect(code).toContain '["OK"]'
        expect(code).toContain '"r":"option"'
        expect(code).toContain '"I am a span"'
        expect(code).toContain 'function anonymous'

    describe 'x.y.js.coffee', ->
      it 'should return transpiled CoffeeScript calling render() and compile()', ->
        view = $('x.y.js.coffee', 'foo bar')
        code = view.render()

        expect(code).toContain 'foo(bar);'
        expect(code).toBe view.compile()

    describe 'x.js.ejs.jade', ->
      view = $('x.js.ejs.jade', 'h1 <%= x %>')

      it 'should return a rendered EJS template calling render()', ->
        code = view.render(x: 'OK')

        expect(code).toContain '<h1>OK</h1>'
        expect(code).not.toContain 'function'

      it 'should return a EJS template calling compile()', ->
        code = view.compile()

        expect(code).toContain 'escape(x)'
        expect(code).toContain 'function anonymous'