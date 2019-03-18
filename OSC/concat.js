var fs = require("fs");
var path = require("path");

fs.readFile(path.join(__dirname,"tinyosc/tinyosc.h"),"utf8",function(err,h) {
	if(err) { console.log(err); return; }
	fs.readFile(path.join(__dirname,"tinyosc/tinyosc.c"),"utf8",function(err,c) {
		if(err) { console.log(err); return; }		
		fs.writeFile(path.join(__dirname,"tinyosc.h"),h+"\n"+c,function (err) {
			if(err) return console.log(err);
		});
	});
});
