(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
"use strict";

CodeMirror.defineMode("dae", function(config) {
  var indentUnit = config.indentUnit;

  function tokenBase(stream, state) {
    if (stream.eatSpace()) return null;

    // Comments (Official: comment.line, comment.block)
    if (stream.match("#")) {
      stream.skipToEnd();
      return "comment";
    }
    if (stream.match("/*")) {
      state.tokenize = tokenBlockComment;
      return tokenBlockComment(stream, state);
    }

    // Word Pattern (Official: bare_literal - ANTLR4 based)
    // ID: [a-zA-Z_]([a-zA-Z_]|[/\\^*.+0-9-]|[=@$!#%])*
    // NON ID: [/\\^*.+0-9-]([a-zA-Z_]|[/\\^*.+0-9-]|[=@$!#%])*
    var wordPattern = /^([a-zA-Z_][a-zA-Z_0-9\/\^*.+\-=@$!#%]*|[\/\^*.+\-0-9][a-zA-Z_0-9\/\^*.+\-=@$!#%]*)/;

    // Outbound detection (Anything after -> or fallback:)
    if (state.expectOutbound) {
      if (stream.match(wordPattern)) {
        state.expectOutbound = false;
        return "keyword";
      }
    }

    // Operators (Official: keyword.operator.*)
    if (stream.match("->")) return "operator marker";
    if (stream.match("&&") || stream.match("!")) return "operator";
    if (stream.match(":")) return "operator";

    // Quoted Strings (Official: quote_literal)
    if (stream.match(/^"([^"\\]|\\.)*"/ ) || stream.match(/^'([^'\\]|\\.)*'/)) return "string";

    // Numbers & IPs (Official: literal - styled as constants in Dracula)
    // Supports IPv4, IPv6 (including hex prefix), and CIDR notation
    if (stream.match(/^([0-9]+(\.[0-9]+)+(?:\/[0-9]+)?|[a-fA-F0-9:]*::[a-fA-F0-9:]*(?:\/[0-9]+)?|[a-fA-F0-9]+(:[a-fA-F0-9]+){2,}(?:\/[0-9]+)?|[0-9]+(\.[0-9]+)?(%|[a-zA-Z]+)?)/)) return "number";

    // Struct/Block Header (Official: storage.type.struct)
    if (stream.match(new RegExp(wordPattern.source.slice(1) + "\\s*(?={)"))) {
      return "keyword";
    }

    // Tag Prefixes (Official: constant.other.id - Styled as variable-2 Cyan)
    if (stream.match(/^(geosite|geoip|pname|domain|dip|sip|dport|sport|l4proto|ipversion_prefer|fixed_domain_ttl)(?=\s*:)/)) {
        return "variable-2";
    }

    // Parameters (Official: variable.parameter - Styled as variable-3 Orange)
    if (stream.match(new RegExp(wordPattern.source.slice(1) + "(?=\\s*:)"))) {
        return "variable-3";
    }

    // Functions/Matchers (Official: entity.name.function)
    // Supports (!)? prefix
    if (stream.match(new RegExp("(!)?\\s*" + wordPattern.source.slice(1) + "\\s*(?=\\()"))) {
        return "def";
    }

    // Official Keywords (Official: outbound)
    if (stream.match(/^(block|direct)\b/)) {
        return "keyword";
    }

    // Brackets & Annotations
    if (stream.match(/^[{}()\[\]]/)) return "bracket";

    // Fallback Word (Official: literal)
    if (stream.match(wordPattern)) {
      return "variable";
    }

    stream.next();
    return null;
  }

  function tokenBlockComment(stream, state) {
    while (!stream.eol()) {
      if (stream.match("*/")) {
        state.tokenize = tokenBase;
        break;
      }
      stream.next();
    }
    return "comment";
  }

  return {
    startState: function() {
      return { tokenize: tokenBase, stack: [], expectOutbound: false };
    },
    token: function(stream, state) {
      var style = state.tokenize(stream, state);
      var cur = stream.current();
      if (style === "operator marker") {
        state.expectOutbound = true;
      } else if (style === "variable-3" && cur === "fallback") {
        state.expectOutbound = true;
      } else if (style !== null && style !== "comment" && !/^\s*:?\s*$/.test(cur)) {
        state.expectOutbound = false;
      }
      if (cur == "{") state.stack.push("{");
      else if (cur == "}") state.stack.pop();
      return style;
    },
    indent: function(state, textAfter) {
      var n = state.stack.length;
      if (/^\}/.test(textAfter)) n--;
      return n * indentUnit;
    },
    lineComment: "#",
    blockCommentStart: "/*",
    blockCommentEnd: "*/",
    fold: "brace"
  };
});

CodeMirror.defineMIME("text/x-dae", "dae");
});
