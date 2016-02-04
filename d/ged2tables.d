import std.stdio, std.string, std.conv;

string peekBit(string s) {
	auto index = s.indexOf(' ');
	if (index < 0) return s;
	return s[0..index];
}
string popBit(ref string s) {
	auto index = s.indexOf(' ');
	if (index < 0) {
		string ans = s;
		s = null;
		return ans;
	} else {
		string ans = s[0..index];
		s = s[index+1..$];
		return ans;
	}
}

struct gedLine {
	int depth;
	string tag;
	string id;
	string xlink;
	string content;
	this(string line) {
		string d = line.popBit;
		if (d.length == 1) depth = d[0] - '0';
		else depth = to!int(d, 10);
		
		tag = line.popBit;
		if (tag[0] == '@' && tag[$-1] == '@') {
			id = tag[1..$-1];
			tag = line.popBit;
		}
		
		string link = line.peekBit;
		if (link.length > 0 && link[0] == '@' && link[$-1] == '@') {
			xlink = link[1..$-1];
			line.popBit;
		}
		
		content = line;
	}
	string toString() {
		string ans = "<"~tag;
		if (xlink) ans ~= " xlink:href=\"#"~xlink~"\"";
		if (id) ans ~= " id=\""~id~"\"";
		return ans ~ ">" ~ content;
	}
}

string[string] readPerson(ref bufFile f, string[string] notes) {
	string line = f.peek.strip;
	if (line is null) { f.pop; return null; }
	gedLine gl = line;
	if (gl.depth != 0 || gl.tag != "INDI") { f.pop; return null; }
	f.pop;
	string[string] ans;
	ans[`id`] = gl.id;


	gedLine[] nested = [gl];
	void begin(gedLine g) {
		if (g.depth == 2 && g.tag == "GIVN" && nested[$-1].tag == "NAME") {
			ans[`givenName`] = g.content;
		}
		if (g.depth == 2 && g.tag == "SURN" && nested[$-1].tag == "NAME") {
			ans[`familyName`] = g.content;
		}
		if (g.depth == 1 && g.tag == "SEX") {
			ans[`sex`] = g.content;
		}
		if (g.depth == 2 && g.tag == "DATE" && nested[$-1].tag == "BIRT") {
			ans[`birthDate`] = g.content;
		}
		if (g.depth == 2 && g.tag == "PLAC" && nested[$-1].tag == "BIRT") {
			ans[`birthPlace`] = g.content;
		}
		if (g.depth == 2 && g.tag == "DATE" && nested[$-1].tag == "DEAT") {
			ans[`deathDate`] = g.content;
		}
		if (g.depth == 2 && g.tag == "PLAC" && nested[$-1].tag == "DEAT") {
			ans[`deathPlace`] = g.content;
		}
		if (g.depth == 2 && g.tag == "PLAC" && nested[$-1].tag == "BURI") {
			ans[`burialPlace`] = g.content;
		}
		if (g.depth == 1 && g.tag == "_UID") {
			ans[`_UID`] = g.content;
		}
		if (g.depth == 1 && g.tag == "FAMS") {
			if (`spouse` !in ans) ans[`spouse`] = g.xlink;
			else ans[`spouse`] = ans[`spouse`] ~ ";" ~g.xlink;
		}
		if (g.depth == 1 && g.tag == "FAMC") {
			ans[`parents`] = g.xlink;
		}
		if (g.tag == "NOTE") {
			if (`notes` !in ans) ans[`notes`] = g.content.strip;
			else ans[`notes`] = ans[`notes`] ~ "\n----\n" ~g.content.strip;
			if (g.xlink !is null)
				if (g.xlink in notes) ans[`notes`] ~= notes[g.xlink];
				else ans[`notes`] ~= "see @"~g.xlink~"@";
		}
		nested ~= g;
	}
	void end() {
		// do something with nested[$-1]
		nested.length = nested.length - 1;
	}
	
	gedLine last = gl;
	while(f.peek && f.peek[0] != '0') {
		gl = gedLine(f.pop.strip);
		if (gl.tag == "CONT") {
			assert(gl.depth == last.depth + 1);
			assert(gl.id == null);
			last.content ~= "\n"~gl.content;
		} else if (gl.tag == "CONC") {
			assert(gl.depth == last.depth + 1);
			assert(gl.id == null);
			last.content ~= gl.content;
		} else {
			while(last.depth < nested.length) end();
			assert(last.depth == nested.length);
			begin(last);
			last = gl;
		}
	}
	while(nested.length > 0) end();
	return ans;
}

string[string] readFamily(ref bufFile f, string[string] notes) {
	string line = f.peek.strip;
	if (line is null) { f.pop; return null; }
	gedLine gl = line;
	if (gl.depth != 0 || gl.tag != "FAM") { f.pop; return null; }
	f.pop;
	string[string] ans;
	ans[`id`] = gl.id;

	gedLine[] nested = [gl];
	void begin(gedLine g) {
		if (g.depth == 2 && g.tag == "DATE" && nested[$-1].tag == "MARR") {
			ans[`marriageDate`] = g.content;
		}
		if (g.depth == 2 && g.tag == "PLAC" && nested[$-1].tag == "MARR") {
			ans[`marriagePlace`] = g.content;
		}
		if (g.depth == 1 && g.tag == "HUSB") {
			ans[`husband`] = g.xlink;
		}
		if (g.depth == 1 && g.tag == "WIFE") {
			ans[`wife`] = g.xlink;
		}
		if (g.depth == 1 && g.tag == "CHIL") {
			if (`chuldren` !in ans) ans[`children`] = g.xlink;
			else ans[`children`] = ans[`children`] ~ ";" ~g.xlink;
		}
		if (g.tag == "NOTE") {
			if (`notes` !in ans) ans[`notes`] = g.content.strip;
			else ans[`notes`] = ans[`notes`] ~ "\n----\n" ~g.content.strip;
			if (g.xlink !is null)
				if (g.xlink in notes) ans[`notes`] ~= notes[g.xlink];
				else ans[`notes`] ~= "see @"~g.xlink~"@";
		}
		nested ~= g;
	}
	void end() {
		// do something with nested[$-1] ???
		nested.length = nested.length - 1;
	}
	
	gedLine last = gl;
	while((line = f.peek) != null) {
		if (line[0] == '0') break;
		gl = gedLine(f.pop.strip);
		if (gl.tag == "CONT") {
			assert(gl.depth == last.depth + 1);
			assert(gl.id == null);
			last.content ~= "\n"~gl.content;
		} else if (gl.tag == "CONC") {
			assert(gl.depth == last.depth + 1);
			assert(gl.id == null);
			last.content ~= gl.content;
		} else {
			while(last.depth < nested.length) end();
			assert(last.depth == nested.length);
			begin(last);
			last = gl;
		}
	}
	while(nested.length > 0) end();
	
	return ans;
}


string asCSVRow(string[string] person, string header="id,familyName,givenName,sex,birthDate,deathDate,parents,notes") {
	string[] headers = header.split(",");
	string ans = "";
	foreach(key; headers) {
		if (key != headers[0]) ans ~= ",";
		if (key in person) {
			bool needQuote = false;
			foreach(char c; person[key]) {
				if (c == ',' || c == '\n' || c == '\r' || c == '"') needQuote = true;
			}
			if (needQuote) {
				ans ~= `"`;
				foreach(char c; person[key]) {
					if (c == '"') ans ~= `""`;
					else ans ~= c;
				}
				ans ~= `"`;
			} else {
				ans ~= person[key];
			}
		}
	}
	return ans;
}

struct bufFile {
	File readFrom;
	string[] buffer;
	this(ref File f) { this.readFrom = f; }
	this(string fname) { this.readFrom = File(fname); }
	string peek() {
		if (buffer.length > 0) {
			return buffer[$-1];
		} else if (readFrom.eof) {
			return null;
		} else {
			buffer ~= readFrom.readln();
			return buffer[$-1];
		}
	}
	string pop() {
		if (buffer.length > 0) {
			string ans = buffer[$-1];
			buffer.length = buffer.length - 1;
			return ans;
		}
		else if (readFrom.eof) return null;
		else {
			return readFrom.readln();
		}
	}
	void push(string line) {
		buffer ~= line;
	}
}

void main(string[] args) {
	if (args.length == 1) {
		stderr.writeln("USAGE: ", args[0], " someGedcom.ged");
		return;
	}
	string BOM = "\uFEFF";
	foreach(arg; args[1..$]) {
		
		string[] tags;
		gedLine last = "0 gedcom55";
		auto s = bufFile(arg);
		
		File personOut = File(arg~".person.csv", "w");
		personOut.writeln("id,familyName,givenName,sex,birthDate,deathDate,parents,notes");
		File marriageOut = File(arg~".marriage.csv", "w");
		marriageOut.writeln("id,husband,wife,marriageDate,notes");
		
		string[string] notes;
		
		string line;

		while((line = s.pop) != null) {
			if (line[0..BOM.length] == BOM) line = line[BOM.length..$];
			if (line[0] == '0' && line[$-6..$-2] == "NOTE") {
				last = gedLine(line.strip());
				while(s.peek && s.peek[0] != '0') {
					auto gl = gedLine(s.pop.strip);
					if (gl.tag == "CONT") {
						assert(gl.depth == last.depth + 1);
						assert(gl.id == null);
						last.content ~= "\n"~gl.content;
					} else if (gl.tag == "CONC") {
						assert(gl.depth == last.depth + 1);
						assert(gl.id == null);
						last.content ~= gl.content;
					} else {
						break;
					}
				}
				notes[last.id] = last.content;
			} else {
				// ignore this line
			}
		}

		s = bufFile(arg);

		while((line = s.pop) != null) {
			if (line[0..BOM.length] == BOM) line = line[BOM.length..$];
			if (line[0] == '0' && line[$-6..$-2] == "INDI") {
				s.push(line);
				auto p = readPerson(s, notes);
				personOut.writeln(p.asCSVRow);
				personOut.flush;
			} else if (line[0] == '0' && line[$-5..$-2] == "FAM") {
				s.push(line);
				auto p = readFamily(s, notes);
				marriageOut.writeln(asCSVRow(p,"id,husband,wife,marriageDate,notes"));
				marriageOut.flush;
			} else {
				// ignore this line
			}
		}
		personOut.close;
		marriageOut.close;
	}
}
