// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_util;

//=========================== Disable Spellcheck ===========================

const _jsSetDisableSpellCheckTimer = '''
var disableSpellCheck = setInterval(function () {
      var elements = document.getElementsByTagName('flt-glass-pane');
      var glassPane = elements.length > 0 ? elements[0] : null;
      var shadowRoot = glassPane ? glassPane.shadowRoot : null;
      if (!shadowRoot) {
        return;
      }
      for (let child of shadowRoot.children) {
        if (child.tagName.toLowerCase() == 'form') {
          let textFields = child.getElementsByTagName('textarea');
          for (let textField of textFields) {
            textField.setAttribute('spellcheck', 'false');
          }
        }
      }
    }, 1000);
''';

bool _isTimerSet = false;

void disableSpellCheck() {
  if (!_isTimerSet) {
    js.globalContext.callMethod(
      'eval'.toJS,
      _jsSetDisableSpellCheckTimer.toJS,
    );
    _isTimerSet = true;
  }
}

//=========================== Disable Builtin Search ===========================

// 114 -> F3
// 70  -> F
const _jsDisableBuiltinSearch = '''
  window.addEventListener("keydown",function (e) {
    if (e.keyCode === 114 || ((e.ctrlKey || e.metaKey) && e.keyCode === 70)) {
      e.preventDefault();
    }
  })
''';

void disableBuiltInSearch() {
  js.globalContext.callMethod('eval'.toJS, _jsDisableBuiltinSearch.toJS);
}
