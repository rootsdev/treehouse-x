/**
 * This is intended to be a lightweight (no error checking) implementation
 * of the gedcomx conceptual model.
 * 
 * Note: created from diagram, not from spec.  TODO: fill in rest of spec.
 */
module gxmodel;

alias URI = string;

struct Nullable(T) {
	bool nulled;
	T value;
}

///////////////////////////////////////////////////////////////////////

/// Per the spec, do not participate in inheritance and do not allow extension elements
struct Identifier {
	string value; // required
	URI type;
}
/// ditto
struct Qualifier {
	URI name; // required
	string value;
}
/// ditto
struct TextValue {
	string lang;
	string value; // required
}

//////////////////////////////////////////////////////////////////////

class Attribution {
	URI contributor;
	Nullable!int modified;
	string changeMessage;
}

class SourceReference {
	URI description; // required
	Attribution attribution;
}

class EvidenceReference {
	URI resource; // required
	Attribution attribution;
}

class PlaceReference {
	TextValue original;
	URI descriptionRef;
}


class Note {
	string lang, subject;
	string text; // required
	Attribution attribution;
}

abstract class Conclusion {
	string id, lang;
	SourceReference[] sources;
	URI analysis;
	Note[] notes;
	URI confidience;
}

abstract class Subject : Conclusion {
	Nullable!bool extracted;
	EvidenceReference[] evidence;
	SourceReference[] media;
	Identifier[] identifiers;
	Attribution[] attribution;
}

class Gender : Conclusion {
	URI type; // required
}

class NamePart {
	URI type;
	string value; // required
	Qualifier[] qualifiers;
}

class NameForm {
	string lang;
	string fullText;
	NamePart[] parts;
}

class Date {
	string original, format;
}

class Name : Conclusion {
	URI type;
	NameForm[] nameForms; // non-empty
	Date date;
}


class Fact : Conclusion {
	URI type; // required
	Date date;
	PlaceReference place;
	string value;
	Qualifier[] qualifiers;
}

class Person : Subject {
	Nullable!bool private_; // TODO: serialize without _
	Gender gender;
	Name[] names;
	Fact[] facts;
}

class EventRole : Conclusion {
	URI person; // required
	URI type;
	string details;
}

class Event : Subject {
	URI type;
	Date date;
	PlaceReference place;
	EventRole[] roles;
}

class Relationship : Subject {
	URI type;
	URI person1, person2; // required
	Fact[] facts;
}

class PlaceDescription {
	TextValue[] names;
	URI type, place;
	Nullable!double latitude, longitude;
	Date temporalDescription;
	URI spatialDescription;
}

class Document {
	URI type;
	Nullable!bool extracted;
	string textType;
	string text; // required
	Attribution attribution;
}

class Address {
	string value, city, country, postalCode, stateOrProvince;
	string street, street1, street2, street3, street4, street5, street6;
}

class OnlineAccount {
	URI serviceHomepage; // required
	string accountName; // required
}

class Agent {
	string id;
	TextValue[] names;
	URI homepage;
	URI openid;
	OnlineAccount[] accounts;
	URI[] emails, phones;
	Address[] addresses;
	URI person;
}

class SourceCitation {
	string lang;
	string value; // required
}

class SourceDescription {
	string id;
	URI resourceType;
	SourceCitation[] citations; // non-empty
	string mediaType;
	URI about;
	URI mediator;
	SourceReference[] sources;
	URI analysis; // reference to Document
	SourceReference componentOf; // reference to "source"
	TextValue[] titles;
	Note[] notes;
	Attribution attribution;
}
