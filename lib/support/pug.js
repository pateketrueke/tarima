var $ = require('../helpers/resolve');

var pug;

function render(client) {
  return function(params) {
    pug = pug || require($('pug'));

    var method = client ? 'compileClientWithDependenciesTracked' : 'compile';

    var opts = params.options.pug || {};

    opts.filename = params.filename;

    var tpl = pug[method](params.source, opts);

    params.source = !client ? tpl(params.locals) : tpl.body;

    return tpl.dependencies;
  };
}

module.exports = {
  ext: 'html',
  type: 'template',
  support: ['pug', 'jade'],
  requires: ['pug'],
  render: render(),
  compile: render(true),
  included: "var pug=(typeof window!=='undefined'?window:global).pug||require('p'+'ug-runtime');"
};