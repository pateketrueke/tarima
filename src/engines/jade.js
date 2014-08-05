
register_engine('jade', function(params, next) {
  var jade = require('jade');

  if (params.filepath) {
    params.options.filename = params.filepath + '/' + params.filename;
  }

  var compile = function(client) {
    var prefix = '',
        source;

    if (params.options.includes && params.options.includes.jade) {
      prefix = params.options.includes.jade.join('\n');
    }

    source = (prefix ? prefix + '\n' : '') + params.source;

    var partial = jade[client ? 'compileClient' : 'compile'](source, defs_tpl('jade', params));

    return partial;
  };

  if (next('js', 'us', 'hbs', 'html', 'ract')) {
    if (!params.chain) {
      return compile(true).toString();
    }

    return compile();
  }
});
