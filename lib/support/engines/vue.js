var chain = require('siguiente');
var toSource = require('tosource');

var _export = /(module\.)?exports\s*=|export\s+default/;

function fn(code) {
  return 'function(_h, context){' + code + '}';
}

function wrap(view) {
  if (view.errors && view.errors.length) {
    throw new Error(view.errors.join('; '));
  }

  var _code =  '{\n  render: ' + fn(view.render)
    + ',\n  staticRenderFns: [' + view.staticRenderFns.map(fn).join(',\n')
    + ']\n}';

  // https://github.com/znck/rollup-plugin-vue/blob/master/src/vueTransform.js#L50
  _code = _code.replace(/with\(this\)/g, 'if(window.__VUE_WITH_STATEMENT__)');

  return _code;
}

function render(_, self, params, view, key) {
  if (!view[key]) {
    return;
  }

  if (!self.support.isSupported('.' + view[key].lang)) {
    return;
  }

  _.then(function(next) {
    self.render({
      filename: params.name + '.' + view[key].lang,
      options: params.options,
      source: view[key].content,
      parts: [view[key].lang],
      name: params.name,
      data: {},
      deps: []
    }, function(err, data) {
      if (err) {
        next(err);
      } else {
        view[key] = data.source;

        data.deps.forEach(function (dep) {
          params.deps.push(dep);
        });

        next();
      }
    });
  });
}

function compile(params, cb) {
  var vtc = this.vueTemplateCompiler;

  if (params.source.indexOf('<template') === -1 && params.source.indexOf('</template>') === -1) {
    params.source = 'Vue.extend(' + wrap(vtc.compile(params.source)) + ')';
    cb();
  } else {
    var view = vtc.parseComponent(params.source);

    var _ = chain();

    render(_, this, params, view, 'template');
    render(_, this, params, view, 'script');

    if (view.styles && view.styles.length) {
      view.styles.forEach(function(style, key) {
        render(_, this, params, view.styles, key);
      }, this);
    }

    _.run(function(err) {
      if (!err) {
        if (view.template) {
          view.template = wrap(vtc.compile(view.template));
        }

        if (typeof view.script.content !== 'undefined') {
          view.script = view.script.content;
        }

        view.styles = view.styles.map(function(style) {
          return typeof style.content !== 'undefined'
            ? style.content
            : style;
        });

        params.source = [
          view.template ? 'var __tpl$ = ' + view.template + ';\n' : '',
          view.styles ? 'var __css$ = ' + toSource(view.styles) + ';\n' : '',
          (view.script || '').replace(_export, 'var __view$ ='),
          '__view$.render = __tpl$.render;\n',
          '__view$.staticRenderFns = __tpl$.staticRenderFns;\n',
          '__view$.includedStylesheets = __css$;\n',
          (view.script || '').match(_export)[0] + ' Vue.extend(__view$);\n',
        ].join('');
      }

      cb(err);
    });
  }
}

module.exports = {
  ext: 'js',
  type: 'script',
  support: ['vue'],
  requires: ['vue-template-compiler'],
  render: compile,
  compile: compile,
  included: "var Vue=Vue||(typeof window!=='undefined'?window:global).Vue||require('v'+'ue');"
};