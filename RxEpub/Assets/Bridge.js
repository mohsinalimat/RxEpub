var header = document.createElement('div');
header.id="RxEpub_Header";
var body=document.getElementsByTagName('body')[0];
body.insertBefore(header,body.childNodes[0]);

function addCSS(selector, newRule){
    var sheet = document.styleSheets[0];
    if (sheet.addRule){
        sheet.addRule(selector, newRule);
    } else {
        ruleIndex = sheet.cssRules.length;
        sheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);
    }
}
