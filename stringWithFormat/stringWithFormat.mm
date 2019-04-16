#import <Foundation/Foundation.h>

const char *stringWithFormat(const char *format, ...) {
    va_list arg1,arg2;
    va_start(arg1,format);
    va_copy(arg2,arg1);    
    int size = vsnprintf(NULL,0,format,arg1)+1;
    char *str = new char[size];
    vsprintf(str,format,arg2); 
    va_end(arg2);
    va_end(arg1);
    return str;
}
    
int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        const char *html = stringWithFormat(R"(<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title></title>
<style>
* {
    margin:0;
    padding:0;
}
body {
    width: 100%%;
    height: 100vh;
    overflow: hidden;
    font-family:'Hiragino Kaku Gothic Pro','ヒラギノ角ゴ Pro W3',Meiryo,メイリオ,Osaka,'MS PGothic',arial,helvetica,sans-serif;
    //background-color:transparent;
}
div#current {
    position:absolute;
    width:95%%;
    margin-left:2.5%%;
    color:rgba(%d,%d,%d,%f);
    font-size:54px;
    font-weight:bold;
    left:0;
    top:50%%;
    -webkit-transform: translateY(-50%%);
    text-align:center;
    line-height:1.4em;
    word-break: break-all;
    -webkit-font-smoothing:antialiased;
    text-shadow:1.25px 0 0 rgba(22,22,22,0.4),0 1.25px 0 rgba(22,22,22,0.4),-1.25px 0 0 rgba(22,22,22,0.4),0 -1.25px 0 rgba(22,22,22,0.4);
}

</style>
</head>
<body>
<div id="current"><p></p></div>
<script>
    window.current = function (str) {
        var el = document.getElementById("current");
        var p = el.querySelector("p");
        p.textContent = str;
        p.style.textAlign = (p.clientHeight>100)?"left":"center";
    }
</script>
</body>
</html>)",
        ((16777215>>16)&0xFF),
        ((16777215>>8)&0xFF),
        ((16777215)&0xFF),
        0.85);
                
        NSLog(@"%s",html);

    }
}