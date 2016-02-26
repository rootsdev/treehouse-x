import std.datetime;


class GXParseException : Exception {
	this(string msg) { super(msg); }
}


struct SimpleDate {
	short year; byte month, day, hour, minute, second, tzhour, tzmin;
	
	/**
	 * parses a simple date, which is
	 * mandatory year: [+-][0-9][0-9][0-9][0-9][0-9][0-9]
	 * end | time | -[0-1][0-9] month 
	 */
	this(ref string s) {
	
		import std.conv;
		if (s.length < 5) throw new GXParseException("date too short");
		month = day = hour = minute = second = byte.min;
		tzhour = tzmin = 0;

		year = to!short(s[0..5]);
		s = s[5..$];

		if (s.length == 0) return;
		if (s[0] == '-') {
			month = to!byte(s[1..3]);
			s = s[3..$];
			if (s.length == 0) return;
			if (s[0] == '-') {
				day = to!byte(s[1..3]);
				s = s[3..$];
				if (s.length == 0) return;
			}
		}
		if (s[0] == 'T') {
			hour = to!byte(s[1..3]);
			s = s[3..$];
			if (s.length == 0) return;
			if (s[0] == ':') {
				minute = to!byte(s[1..3]);
				s = s[3..$];
				if (s.length == 0) return;
				if (s[0] == ':') {
					second = to!byte(s[1..3]);
					s = s[3..$];
					if (s.length == 0) return;
				}
			}
		}
		if (s[0] == 'Z') {
			s = s[1..$];
		} else if (s[0] == '-' || s[0] == '+') {
			tzhour = to!byte(s[0..3]);
			s = s[3..$];
			if (s.length == 0) return;
			if (s[0] == ':') {
				tzmin = to!byte(s[1..3]);
				if (tzhour == 0 && s[-3] == '-') tzmin *= -1;
				s = s[3..$];
				if (s.length == 0) return;
			}
		} 
	}
	string toString() const {
		char[26] data;
		data[0] = year >= 0 ? '+' : '-';
		auto y = year > 0 ? year : -year;
		auto idx = 0;
		data[++idx] = '0'+((y/1000)%10);
		data[++idx] = '0'+((y/100)%10);
		data[++idx] = '0'+((y/10)%10);
		data[++idx] = '0'+((y/1)%10);
		if (month >= 0) {
			data[++idx] = '-';
			data[++idx] = '0'+((month/10)%10);
			data[++idx] = '0'+((month/1)%10);
			if (day >= 0) {
				data[++idx] = '-';
				data[++idx] = '0'+((day/10)%10);
				data[++idx] = '0'+((day/1)%10);
			}
		}
		if (hour >= 0) {
			data[++idx] = 'T';
			data[++idx] = '0'+((hour/10)%10);
			data[++idx] = '0'+((hour/1)%10);
			if (minute >= 0) {
				data[++idx] = ':';
				data[++idx] = '0'+((minute/10)%10);
				data[++idx] = '0'+((minute/1)%10);
				if (second >= 0) {
					data[++idx] = ':';
					data[++idx] = '0'+((second/10)%10);
					data[++idx] = '0'+((second/1)%10);
				}
			}
			if (tzhour == 0 && tzmin == 0) data[++idx] = 'Z';
		}
		if (tzhour != 0 || tzmin != 0) {
			data[++idx] = tzhour > 0 || (tzhour == 0 && tzmin >= 0) ? '+' : '-';
			short h = tzhour < 0 ? -tzhour : tzhour;
			short m = tzmin < 0 ? -tzmin : tzmin;
			if (tzhour >= 0) {
				data[++idx] = '0'+((tzhour/10)%10);
				data[++idx] = '0'+((tzhour/1)%10);
				if (tzmin != 0) {
					data[++idx] = ':';
					data[++idx] = '0'+((tzmin/10)%10);
					data[++idx] = '0'+((tzmin/1)%10);
				}
			}
		}
		return data[0..idx+1].idup;
	}
}
