// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/5/LICENSE

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
  var defaults = {
    pairs: "()[]{}''\"\"",
    closeBefore: ")]}'\":;>",
    triples: "",
    explode: "[]{}"
  };

  var Pos = CodeMirror.Pos;

  CodeMirror.defineOption("autoCloseBrackets", false, function(cm, val, old) {
    if (old && old != CodeMirror.Init) {
      cm.removeKeyMap(keyMap);
      cm.state.closeBrackets = null;
    }
    if (val) {
      updateConfig(cm, val);
      cm.addKeyMap(keyMap);
    }
  });

  function updateConfig(cm, val) {
    var conf = {
      pairs: defaults.pairs,
      closeBefore: defaults.closeBefore,
      triples: defaults.triples,
      explode: defaults.explode
    };
    if (typeof val == "string") {
      conf.pairs = val;
    } else if (typeof val == "object") {
      for (var prop in val)
        if (val.hasOwnProperty(prop)) conf[prop] = val[prop];
    }
    cm.state.closeBrackets = conf;
  }

  var keyMap = {Backspace: handleBackspace};
  var defaultPairs = "()[]{}''\"\"";
  for (var i = 0; i < defaultPairs.length; i += 2) {
    keyMap["'" + defaultPairs.charAt(i) + "'"] = buildHandler(defaultPairs.charAt(i));
    if (defaultPairs.charAt(i) != defaultPairs.charAt(i + 1))
      keyMap["'" + defaultPairs.charAt(i + 1) + "'"] = handleClose;
  }

  function buildHandler(ch) {
    return function(cm) { return handleChar(cm, ch); };
  }

  function handleChar(cm, ch) {
    var conf = cm.state.closeBrackets;
    if (!conf || cm.getOption("disableInput")) return CodeMirror.Pass;

    var pairs = conf.pairs, pos = pairs.indexOf(ch);
    if (pos == -1) return CodeMirror.Pass;

    var closeBefore = conf.closeBefore;
    var open = pairs.charAt(pos), close = pairs.charAt(pos + 1);
    var isDouble = open == close;

    var ranges = cm.listSelections();
    var type = isDouble ? (pos % 2 ? "close" : "both") : "open";

    for (var i = 0; i < ranges.length; i++) {
      var range = ranges[i], cur = range.head, curChar = cm.getRange(cur, Pos(cur.line, cur.ch + 1));
      if (type == "both" && curChar == close) {
        cm.replaceRange("", cur, Pos(cur.line, cur.ch + 1), "+insert");
        continue;
      }
      if (type == "open" || type == "both") {
        if (range.empty() && curChar && closeBefore.indexOf(curChar) == -1 && !/\s/.test(curChar))
          return CodeMirror.Pass;
      }
    }

    cm.operation(function() {
      for (var i = ranges.length - 1; i >= 0; i--) {
        var range = ranges[i], cur = range.head;
        if (isDouble && cm.getRange(cur, Pos(cur.line, cur.ch + 1)) == close) {
          cm.setCursor(Pos(cur.line, cur.ch + 1));
        } else if (!range.empty()) {
          var selected = cm.getRange(range.from(), range.to());
          cm.replaceRange(open + selected + close, range.from(), range.to(), "+insert");
        } else {
          cm.replaceRange(open + close, cur, cur, "+insert");
          cm.setCursor(Pos(cur.line, cur.ch + 1));
        }
      }
    });
  }

  function handleClose(cm) {
    var conf = cm.state.closeBrackets;
    if (!conf || cm.getOption("disableInput")) return CodeMirror.Pass;

    var ranges = cm.listSelections();
    for (var i = 0; i < ranges.length; i++) {
      var cur = ranges[i].head;
      var curChar = cm.getRange(cur, Pos(cur.line, cur.ch + 1));
      if (!ranges[i].empty() || conf.pairs.indexOf(curChar) % 2 != 1)
        return CodeMirror.Pass;
    }
    cm.operation(function() {
      for (var i = 0; i < ranges.length; i++) {
        var cur = ranges[i].head;
        cm.setCursor(Pos(cur.line, cur.ch + 1));
      }
    });
  }

  function handleBackspace(cm) {
    var conf = cm.state.closeBrackets;
    if (!conf || cm.getOption("disableInput")) return CodeMirror.Pass;

    var pairs = conf.pairs;
    var ranges = cm.listSelections();
    for (var i = 0; i < ranges.length; i++) {
      if (!ranges[i].empty()) return CodeMirror.Pass;
      var cur = ranges[i].head;
      var prevChar = cm.getRange(Pos(cur.line, cur.ch - 1), cur);
      var nextChar = cm.getRange(cur, Pos(cur.line, cur.ch + 1));
      var pos = pairs.indexOf(prevChar);
      if (pos == -1 || pos % 2 != 0 || nextChar != pairs.charAt(pos + 1))
        return CodeMirror.Pass;
    }
    cm.operation(function() {
      for (var i = ranges.length - 1; i >= 0; i--) {
        var cur = ranges[i].head;
        cm.replaceRange("", Pos(cur.line, cur.ch - 1), Pos(cur.line, cur.ch + 1), "+delete");
      }
    });
  }
});
