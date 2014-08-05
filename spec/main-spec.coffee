engines = require('./engines')

validateEngine = require('./validate-engines')
testEngine = require('./test-engine')
tarima = require('../lib/tarima')


describe 'Tarima will', ->
  xit 'should expose a reasonable version for debug', ->
    expect(tarima.version).not.toBeUndefined()
    expect(tarima.version.major).toMatch /^\d+$/
    expect(tarima.version.minor).toMatch /^\d+$/
    expect(tarima.version.micro).toMatch /^\d+$/
    expect(tarima.version.date).toMatch /^\d{8}$/

  describe 'validate engines', ->
    it 'would validate unsupported engines', ->
      expect(-> validateEngine().pass()).toThrow()

    for engine in engines
      expect(-> validateEngine(engine).notPass()).toThrow()
      expect(-> validateEngine(engine).pass()).toThrow()
      testEngine(engine)

    ###

      The idea: pipe out the result from one template to another.

      So, the evaluation order is right to left, if there is no more extensions
      or cannot be evaluated will return it's source code. Otherwise it will parse.

      Here is my essay:

      I want to use this kind of black magic to automatize my source code.
      I want to produce my assets, configs, documents, etc. in a nice an cleaver way.
      I notice that last file's extension rule about it's content and has higher precedence.
      I notice that first file's extension rule about how the file context will be saved, as is.

      Then, source code will produce source code.

      There are few engines:
      - Use .js for js-source (plain old javascript) -- READY (?) --
      - Use .jade for jade-source (templating engine that produces html) -- NOT READY --
      - Use .html for html-source (plain old html-markup) -- NOT READY --
      - Use .ract for ract-source (for ractive.js) -- NOT READY --
      - Use .hbs for hbs-source (handlebars) -- NOT READY --
      - Use .us for us-source (underscore) -- NOT READY --
      - Use .eco for eco-source (embedded coffee) -- NOT READY --
      - Use .ejs for ejs-source (embedded javascript) -- NOT READY --
      - Use .coffee for coffee-source (you known) -- NOT READY --
      - Use .json for json-source (JSON data) -- NOT READY --
      - Use .less for less-source (compile down css stylesheets) -- NOT READY --
      - Use .md for md-source (plain old markdown) -- NOT READY --

      Given a posts.html.md.hbs.us file we could have a file like this:

      # <%= title || 'Untitled' %>

      {{#package}}
      >    <%= JSON.stringify(pkg) %>
      {{/package}}

      {{#links}}- [{{title}}]({{url}})
      {{/links}}

      Using data.json

      {
        title: 'FU',
        links: [
          { title: 'bar', url: '#buzz' }
        ],
        pkg: { name: 'candy' }
      }

      produces somewhat:

      <h1>FU</h1>
      <blockquote>
        <pre>{ "name": "candy" }<pre>
      </blockquote>
      <ul>
        <li>
          <a href="#buzz">bar</a>
        </li>
      </ul>

      Obviously you can't compile between all engines out of the box, to achieve this,
      you'll ensure which one return valid source code for each another.

      Look at src/tarima.js for more info.

    ###

  describe 'piping engines', ->
    it 'foo.litcoffee.hbs.us -- render() should produce modified coffee-code as is', ->
      foo_litcoffee_hbs_us = tarima.parse 'foo.litcoffee.hbs.us', '''
        # <%= title || 'Untitled' %>

        {{#option}}
            fun = ->
        {{/option}}{{^option}}
            class Klass; fun = new Klass
        {{/option}}
      '''

      expect(foo_litcoffee_hbs_us.render(title: off)).toContain 'class Klass'
      expect(foo_litcoffee_hbs_us.compile(title: off)).toContain 'Handlebars.template'

      expect(foo_litcoffee_hbs_us.render(title: 'FTW')).toContain 'class Klass'
      expect(foo_litcoffee_hbs_us.render(title: 'FTW')).not.toContain '# # FTW'
      expect(foo_litcoffee_hbs_us.render(title: 'FTW')).not.toContain 'fun = ->'

      expect(foo_litcoffee_hbs_us.render(option: on, title: off)).toContain 'fun = ->'
      expect(foo_litcoffee_hbs_us.render(option: on, title: off)).not.toContain '# # Untitled'
      expect(foo_litcoffee_hbs_us.render(option: on, title: off)).not.toContain 'class Klass'

    it 'foo.js.hbs.jade.us -- render() should produce modified jade-code as markup', ->
      foo_js_hbs_jade_us = tarima.parse 'foo.js.hbs.jade.us', '''
        h1 <%= title || 'Untitled' %>

        |{{#option}}
        div I am a div
        |{{/option}}{{^option}}
        span I am a span
        |{{/option}}
      '''

      expect(foo_js_hbs_jade_us.render(title: off, option: off)).toBe '<h1>Untitled</h1><span>I am a span</span>'
      expect(foo_js_hbs_jade_us.compile(title: off, option: off)).toContain 'Handlebars.template'
