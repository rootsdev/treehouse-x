import std.datetime : SysTime;
import xmldump;

// spec ambiguities labeled gx:error in comments

struct Maybe(T) {
	bool exists = false;
	T value;
	void opAssign(T val) { exists = true; value = val; }
	void opAssign(typeof(null) nil) { exists = false; }
	alias value this;

	string toString() {
		import std.conv : to;
		if (!exists) return ``;
		return to!string(value);
	}
	/+
	static if (__traits(hasMember, T, `toXML`)) {
		string toXML(string indent=null) {
			if (!exists) return ``;
			return value.toXML(indent);
		}
	}
	+/
}

template isMaybe(U : Maybe!T, T) {
	enum isMaybe = true;
}
template isMaybe(U) {
	enum isMaybe = false;
}

alias Bool  = Maybe!bool;
alias Int   = Maybe!int;
alias Float = Maybe!double;
alias URI = string;        // http://tools.ietf.org/html/rfc3986
alias Enum = URI;
alias LocaleTag = string;  // http://tools.ietf.org/html/bcp47
alias FormalDate = string; // gedcom-x date specification

enum TextType {
	plain = `plain`,
	xhtml = `xhtml`,
}

mixin template idGenerator(string prefix) {
	private static lastId = 0;
	alias Ptr = URI;
	@property Ptr ptr() {
		import std.conv : to;
		if (!id.exists) {
			id.value = prefix ~ to!string(++lastId);
			id.exists = true;
		}
		return `#` ~ id.value;
	}
}

////// TOP LEVEL DATA TYPES //////

class Person : Subject {
	enum identifier = `http://gedcomx.org/v1/Person`;
	@Attr @Named(`private`) Maybe!bool private_; // strip _ in serialisation
	@Prop Maybe!Gender gender;
	@Prop @Named(`name`) Name[] names;
	@Prop @Named(`fact`) Fact[] facts;
	
	mixin idGenerator!(`P_`);
	mixin addToXML!();
}

class Relationship : Subject {
	enum identifier = `http://gedcomx.org/v1/Relationship`;
	enum Types : Enum {
		couple = `http://gedcomx.org/Couple`, /// A relationship of a pair of persons.
		parentChild = `http://gedcomx.org/ParentChild`, /// A relationship from a parent to a child.
	}
	@Attr Maybe!Enum type;
	@Prop Person.Ptr person1;
	@Prop Person.Ptr person2;
	@Prop @Named(`fact`) Fact[] facts;
	mixin addToXML!();
}

class SourceDescription {
	enum identifier = `http://gedcomx.org/v1/SourceDescription`;
	enum ResourceTypes : Enum {
		collection = `http://gedcomx.org/Collection`, /// A collection of genealogical resources. A collection may contain physical artifacts (such as a collection of books in a library), records (such as the 1940 U.S. Census), or digital artifacts (such as an online genealogical application).
		physicalArtifact = `http://gedcomx.org/PhysicalArtifact`, /// A physical artifact, such as a book.
		digitalArtifact = `http://gedcomx.org/DigitalArtifact`, /// A digital artifact, such as a digital image of a birth certificate or other record.
		record = `http://gedcomx.org/Record`, /// A historical record, such as a census record or a vital record.
	}
	@Attr Maybe!string id;
	@Attr Maybe!Enum resourceType;
	@Prop @Named(`citation`) SourceCitation[] citations;
	@Attr Maybe!string mediaType;
	@Attr Maybe!URI about;
	@Prop Maybe!(Agent.Ptr) mediator;
	@Prop @Named(`source`) SourceReference[] sources;
	@Prop Maybe!(Document.Ptr) analysis;
	@Prop Maybe!SourceReference componentOf;
	@Prop @Named(`title`) TextValue[] titles;
	@Prop @Named(`note`) Note[] notes;
	@Prop Maybe!Attribution attribution;
	@Prop URI[] rights;
	@Prop Maybe!Coverage coverage;
	@Prop @Named(`description`) TextValue[] descriptions;
	@Prop @Named(`identifier`) Identifier[] identifiers;
	@Prop @Wrapped Maybe!SysTime created; // FIXME: wrong datatype
	@Prop @Wrapped Maybe!SysTime modified; // FIXME: wrong datatype
	@Prop Maybe!(Agent.Ptr) repository;

	mixin idGenerator!(`SD_`);
	mixin addToXML!();
}

class Agent {
	enum identifier = `http://gedcomx.org/v1/Agent`;
	@Attr Maybe!string id;
	@Prop @Named(`identifier`) Identifier[] identifiers;
	@Prop @Named(`name`) TextValue[] names;
	@Prop Maybe!URI homepage; // gx:error @Wrapped in example, not in description
	@Prop Maybe!URI openid; // gx:error @Wrapped in example, not in description
	@Prop @Named(`account`) OnlineAccount[] accounts;
	@Prop @Named(`email`) URI[] emails; // must use `mailto:` scheme
	@Prop @Named(`phone`) URI[] phones; // must be `tel:` scheme
	@Prop @Named(`address`) Address[] addresses;
	@Prop Maybe!(Person.Ptr) person;

	mixin idGenerator!(`A_`);
	mixin addToXML!();
}

class Event : Subject {
	enum identifier = `http://gedcomx.org/v1/Event`;
	@Attr Maybe!Enum type;
	@Prop Maybe!Date date;
	@Prop Maybe!PlaceReference place;
	@Prop @Named(`role`) EventRole[] roles;
	mixin addToXML!();

	enum Types : Enum {
		adoption = `http://gedcomx.org/Adoption`, /// An adoption event.
		adultChristening = `http://gedcomx.org/AdultChristening`, /// An adult christening event.
		annulment = `http://gedcomx.org/Annulment`, /// An annulment event of a marriage.
		baptism = `http://gedcomx.org/Baptism`, /// A baptism event.
		barMitzvah = `http://gedcomx.org/BarMitzvah`, /// A bar mitzvah event.
		batMitzvah = `http://gedcomx.org/BatMitzvah`, /// A bat mitzvah event.
		birth = `http://gedcomx.org/Birth`, /// A birth event.
		blessing = `http://gedcomx.org/Blessing`, /// A an official blessing event, such as at the hands of a clergy member or at another religious rite.
		burial = `http://gedcomx.org/Burial`, /// A burial event.
		census = `http://gedcomx.org/Census`, /// A census event.
		christening = `http://gedcomx.org/Christening`, /// A christening event *at birth*. Note: use `AdultChristening` for a christening event as an adult.
		circumcision = `http://gedcomx.org/Circumcision`, /// A circumcision event.
		confirmation = `http://gedcomx.org/Confirmation`, /// A confirmation event (or other rite of initiation) in a church or religion.
		cremation = `http://gedcomx.org/Cremation`, /// A cremation event after death.
		death = `http://gedcomx.org/Death`, /// A death event.
		divorce = `http://gedcomx.org/Divorce`, /// A divorce event.
		divorceFiling = `http://gedcomx.org/DivorceFiling`, /// A divorce filing event.
		education = `http://gedcomx.org/Education`, /// A education or an educational achievement event (e.g. diploma, graduation, scholarship, etc.).
		engagement = `http://gedcomx.org/Engagement`, /// An engagement to be married event.
		emigration = `http://gedcomx.org/Emigration`, /// An emigration event.
		excommunication = `http://gedcomx.org/Excommunication`, /// An excommunication event from a church.
		firstCommunion = `http://gedcomx.org/FirstCommunion`, /// A first communion event.
		funeral = `http://gedcomx.org/Funeral`, /// A funeral event.
		immigration = `http://gedcomx.org/Immigration`, /// An immigration event.
		landTransaction = `http://gedcomx.org/LandTransaction`, /// A land transaction event.
		marriage = `http://gedcomx.org/Marriage`, /// A marriage event.
		militaryAward = `http://gedcomx.org/MilitaryAward`, /// A military award event.
		militaryDischarge = `http://gedcomx.org/MilitaryDischarge`, /// A military discharge event.
		mission = `http://gedcomx.org/Mission`, /// A mission event.
		moveFrom = `http://gedcomx.org/MoveFrom`, /// An event of a move (i.e. change of residence) from a location.
		moveTo = `http://gedcomx.org/MoveTo`, /// An event of a move (i.e. change of residence) to a location.
		naturalization = `http://gedcomx.org/Naturalization`, /// A naturalization event (i.e. acquisition of citizenship and nationality).
		ordination = `http://gedcomx.org/Ordination`, /// An ordination event.
		retirement = `http://gedcomx.org/Retirement`, /// A retirement event.
	}
}

class Document : Conclusion {
	enum identifier = `http://gedcomx.org/v1/Document`;
	enum Type : URI {
		abstract_ = `http://gedcomx.org/Abstract`, /// The document is an abstract of a record or document.
		transcription = `http://gedcomx.org/Transcription`, /// The document is a transcription of a record or document.
		translation = `http://gedcomx.org/Translation`, /// The document is a translation of a record or document.
		analysis = `http://gedcomx.org/Analysis`, /// The document is an analysis done by a researcher; a genealogical proof statement is an example of one kind of analysis document.
	}
	@Attr Maybe!Enum type;
	@Attr Maybe!bool extracted;
	@Attr Maybe!TextType textType;
	@Prop @Wrapped string text;
	@Prop Maybe!Attribution attribution;
	
	alias Ptr = URI;
	mixin idGenerator!(`D_`);
	mixin addToXML!();
}

class PlaceDescription : Subject {
	enum identifier = `http://gedcomx.org/v1/PlaceDescription`;
	@Named(`name`) TextValue[] names; /// must not be empty
	@Attr Maybe!Enum type;
	@Prop Maybe!URI place;
	@Prop Maybe!(PlaceDescription.Ptr) jurisdiction;
	@Prop @Wrapped Maybe!double latitude;
	@Prop @Wrapped Maybe!double longitude;
	@Prop Maybe!Date temporalDescription;
	@Prop Maybe!URI spatialDescription; /// should resolve to KML document

	alias Ptr = URI;
	mixin idGenerator!(`PD_`);
	mixin addToXML!();
}

/////// Component-level Data Types ///////

struct Identifier {
	enum identifier = `http://gedcomx.org/v1/Identifier`;
	enum Type : Enum {
		primary = `http://gedcomx.org/Primary`, /// The primary identifier for the resource. The value of the identifier MUST resolve to the instance of `Subject` to which the identifier applies.
		authority = `http://gedcomx.org/Authority`, /// An identifier for the resource in an external authority or other expert system. The value of the identifier MUST resolve to a public, authoritative, source for information about the `Subject` to which the identifier applies.
		deprecated_ = `http://gedcomx.org/Deprecated`, /// An identifier that has been relegated, deprecated, or otherwise downgraded. This identifier is commonly used as the result of a merge when what was once a primary identifier for a resource is no longer the primary identifier. The value of the identifier MUST resolve to the instance of `Subject` to which the identifier applies.
	}
	@Prop @FlatContent URI value;
	@Attr Maybe!Enum type;
	mixin addToXML!();
}

class Attribution {
	enum identifier = `http://gedcomx.org/v1/Attribution`;
	@Prop Maybe!(Agent.Ptr) contributor;
	@Prop @Wrapped Maybe!SysTime modified;
	@Prop @Wrapped Maybe!string changeMessage;
	mixin addToXML!();
}

class Note {
	enum identifier = `http://gedcomx.org/v1/Note`;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
	@Prop @Wrapped Maybe!string subject;
	@Prop @Wrapped string text;
	@Prop Maybe!Attribution attribution;
	mixin addToXML!();
}

struct TextValue {
	enum identifier = `http://gedcomx.org/v1/TextValue`;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
	@Prop @FlatContent string value;
	mixin addToXML!();
}

class SourceCitation {
	enum identifier = `http://gedcomx.org/v1/SourceCitation`;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
	@Prop string value;
	// gx:error xml-format says need attribute 'textType' of value
	mixin addToXML!();
}

class SourceReference {
	enum identifier = `http://gedcomx.org/v1/SourceReference`;
	@Attr SourceDescription.Ptr description;
	@Prop Maybe!Attribution attribution;
	mixin addToXML!();
}

class EvidenceReference {
	enum identifier = `http://gedcomx.org/v1/EvidenceReference`;
	@Attr Subject.Ptr resource;
	@Prop Maybe!Attribution attribution;
	// gx:error xml-format example suggests a URI analysis field too
	mixin addToXML!();
}

class OnlineAccount {
	enum identifier = `http://gedcomx.org/v1/OnlineAccount`;
	@Prop URI serviceHomepage;
	@Prop @Wrapped string accountName;
	mixin addToXML!();
}

class Address {
	enum identifier = `http://gedcomx.org/v1/Address`;
    @Prop @Wrapped Maybe!string value;
    @Prop @Wrapped Maybe!string city;
	@Prop @Wrapped Maybe!string country;
	@Prop @Wrapped Maybe!string postalCode;
    @Prop @Wrapped Maybe!string stateOrProvince;
    @Prop @Wrapped Maybe!string street;
    @Prop @Wrapped Maybe!string street2;
    @Prop @Wrapped Maybe!string street3;
    @Prop @Wrapped Maybe!string street4;
    @Prop @Wrapped Maybe!string street5;
    @Prop @Wrapped Maybe!string street6;
	mixin addToXML!();
}

abstract class Conclusion {
	enum identifier = `http://gedcomx.org/v1/Conclusion`;
	@Attr Maybe!string id;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
    @Prop @Named(`source`) SourceReference[] sources;
    @Prop Maybe!(Document.Ptr) analysis; // must have type `http://gedcomx.org/Analysis`.
    @Prop @Named(`note`) Note[] notes;
    @Attr Maybe!Enum confidence;
    
    enum ConfidenceLevel : Enum {
		high = `http://gedcomx.org/High`, /// The contributor has a high degree of confidence that the assertion is true.
		medium = `http://gedcomx.org/Medium`, /// The contributor has a medium degree of confidence that the assertion is true.
		low = `http://gedcomx.org/Low`, /// The contributor has a low degree of confidence that the assertion is true.
	}
}

abstract class Subject : Conclusion {
	enum identifier = `http://gedcomx.org/v1/Subject`;
	@Attr Maybe!bool extracted;
	@Prop EvidenceReference[] evidence; // MUST have same type as this; a Person's evidence must be Persons
	@Prop SourceReference[] media;
	@Prop @Named(`identifier`) Identifier[] identifiers;
	@Prop Maybe!Attribution attribution;
	
	alias Ptr = URI;
}

class Gender : Conclusion {
	enum identifier = `http://gedcomx.org/v1/Gender`;
	@Attr Enum type;
	enum Type : Enum {
		male = `http://gedcomx.org/Male`, /// Male gender.
		female = `http://gedcomx.org/Female`, /// Female gender.
		unknown = `http://gedcomx.org/Unknown`, /// Unknown gender.
	}
	mixin addToXML!();
}

class Name : Conclusion {
	enum identifier = `http://gedcomx.org/v1/Name`;
	@Attr Maybe!Enum type;
	@Prop @Named(`nameForm`) NameForm[] nameForms; // must be non-empty
	@Attr Maybe!Date date;
	enum Type : Enum {
		birthName = `http://gedcomx.org/BirthName`, /// Name given at birth.
		marriedName = `http://gedcomx.org/MarriedName`, /// Name accepted at marriage.
		alsoKnownAs = `http://gedcomx.org/AlsoKnownAs`, /// "Also known as" name.
		nickname = `http://gedcomx.org/Nickname`, /// Nickname.
		adoptiveName = `http://gedcomx.org/AdoptiveName`, /// Name given at adoption.
		formalName = `http://gedcomx.org/FormalName`, /// A formal name, usually given to distinguish it from a name more commonly used.
		religiousName = `http://gedcomx.org/ReligiousName`, /// A name given at a religious rite or ceremony.
	}
	mixin addToXML!();
}

class Fact : Conclusion {
	enum identifier = `http://gedcomx.org/v1/Fact`;
	@Attr Enum type;
	@Prop Maybe!Date date;
	@Prop Maybe!PlaceReference place;
	@Prop @Wrapped Maybe!string value;
	@Prop @Named(`qualifier`) Qualifier[] qualifiers;

	mixin addToXML!();
	
	enum Type : Enum {
		adoption = `http://gedcomx.org/Adoption`, /// A fact of a person's adoption.
		adultChristening = `http://gedcomx.org/AdultChristening`, /// A fact of a person's christening or baptism as an adult.
		amnesty = `http://gedcomx.org/Amnesty`, /// A fact of a person's amnesty.
		apprenticeship = `http://gedcomx.org/Apprenticeship`, /// A fact of a person's apprenticeship.
		arrest = `http://gedcomx.org/Arrest`, /// A fact of a person's arrest.
		baptism = `http://gedcomx.org/Baptism`, /// A fact of a person's baptism.
		barMitzvah = `http://gedcomx.org/BarMitzvah`, /// A fact of a person's bar mitzvah.
		batMitzvah = `http://gedcomx.org/BatMitzvah`, /// A fact of a person's bat mitzvah.
		birth = `http://gedcomx.org/Birth`, /// A fact of a person's birth.
		blessing = `http://gedcomx.org/Blessing`, /// A fact of an official blessing received by a person, such as at the hands of a clergy member or at another religious rite.
		burial = `http://gedcomx.org/Burial`, /// A fact of the burial of a person's body after death.
		caste = `http://gedcomx.org/Caste`, /// A fact of a person's caste.
		census = `http://gedcomx.org/Census`, /// A fact of a person's participation in a census.
		christening = `http://gedcomx.org/Christening`, /// A fact of a person's christening *at birth*. Note: Use `AdultChristening` for the christening as an adult.
		circumcision = `http://gedcomx.org/Circumcision`, /// A fact of a person's circumcision.
		clan = `http://gedcomx.org/Clan`, /// A fact of a person's clan.
		confirmation = `http://gedcomx.org/Confirmation`, /// A fact of a person's confirmation (or other rite of initiation) in a church or religion.
		cremation = `http://gedcomx.org/Cremation`, /// A fact of the cremation of person's body after death.
		death = `http://gedcomx.org/Death`, /// A fact of the death of a person.
		education = `http://gedcomx.org/Education`, /// A fact of an education or an educational achievement (e.g., diploma, graduation, scholarship, etc.) of a person.
		emigration = `http://gedcomx.org/Emigration`, /// A fact of the emigration of a person.
		ethnicity = `http://gedcomx.org/Ethnicity`, /// A fact of a person's ethnicity or race.
		excommunication = `http://gedcomx.org/Excommunication`, /// A fact of a person's excommunication from a church.
		firstCommunion = `http://gedcomx.org/FirstCommunion`, /// A fact of a person's first communion in a church.
		funeral = `http://gedcomx.org/Funeral`, /// A fact of a person's funeral.
		genderChange = `http://gedcomx.org/GenderChange`, /// A fact of a person's gender change.
		heimat = `http://gedcomx.org/Heimat`, /// A fact of a person's _heimat_. "Heimat" refers to a person's affiliation by birth to a specific geographic place. Distinct heimaten are often useful as indicators that two persons of the same name are not likely to be closely related genealogically. In English, "heimat" may be described using terms like "ancestral home", "homeland", or "place of origin".
		immigration = `http://gedcomx.org/Immigration`, /// A fact of a person's immigration.
		imprisonment = `http://gedcomx.org/Imprisonment`, /// A fact of a person's imprisonment.
		landTransaction = `http://gedcomx.org/LandTransaction`, /// A fact of a land transaction enacted by a person.
		language = `http://gedcomx.org/Language`, /// A fact of a language spoken by a person.
		living = `http://gedcomx.org/Living`, /// A fact of a record of a person's living for a specific period. This is designed to include "flourish", defined to mean the time period in an adult's life where he was most productive, perhaps as a writer or member of the state assembly. It does not reflect the person's birth and death dates.
		maritalStatus = `http://gedcomx.org/MaritalStatus`, /// A fact of a person's marital status.
		medical = `http://gedcomx.org/Medical`, /// A fact of a person's medical record, such as for an illness or hospital stay.
		militaryAward = `http://gedcomx.org/MilitaryAward`, /// A fact of a person's military award.
		militaryDischarge = `http://gedcomx.org/MilitaryDischarge`, /// A fact of a person's military discharge.
		militaryDraftRegistration = `http://gedcomx.org/MilitaryDraftRegistration`, /// A fact of a person's registration for a military draft.
		militaryInduction = `http://gedcomx.org/MilitaryInduction`, /// A fact of a person's military induction.
		militaryService = `http://gedcomx.org/MilitaryService`, /// A fact of a person's military service.
		mission = `http://gedcomx.org/Mission`, /// A fact of a person's church mission.
		moveTo = `http://gedcomx.org/MoveTo`, /// A fact of a person's move (i.e., change of residence) to a new location.
		moveFrom = `http://gedcomx.org/MoveFrom`, /// A fact of a person's move (i.e., change of residence) from a location.
		multipleBirth = `http://gedcomx.org/MultipleBirth`, /// A fact that a person was born as part of a multiple birth (e.g., twin, triplet, etc.).
		nationalId = `http://gedcomx.org/NationalId`, /// A fact of a person's national id (e.g., social security number).
		nationality = `http://gedcomx.org/Nationality`, /// A fact of a person's nationality.
		naturalization = `http://gedcomx.org/Naturalization`, /// A fact of a person's naturalization (i.e., acquisition of citizenship and nationality).
		numberOfChildren = `http://gedcomx.org/NumberOfChildren`, /// A fact of the number of children of a person or relationship.
		numberOfMarriages = `http://gedcomx.org/NumberOfMarriages`, /// A fact of a person's number of marriages.
		occupation = `http://gedcomx.org/Occupation`, /// A fact of a person's occupation or employment.
		ordination = `http://gedcomx.org/Ordination`, /// A fact of a person's ordination to a stewardship in a church.
		pardon = `http://gedcomx.org/Pardon`, /// A fact of a person's legal pardon.
		physicalDescription = `http://gedcomx.org/PhysicalDescription`, /// A fact of a person's physical description.
		probate = `http://gedcomx.org/Probate`, /// A fact of a receipt of probate of a person's property.
		property = `http://gedcomx.org/Property`, /// A fact of a person's property or possessions.
		religion = `http://gedcomx.org/Religion`, /// A fact of a person's religion.
		residence = `http://gedcomx.org/Residence`, /// A fact of a person's residence.
		retirement = `http://gedcomx.org/Retirement`, /// A fact of a person's retirement.
		stillbirth = `http://gedcomx.org/Stillbirth`, /// A fact of a person's stillbirth.
		will = `http://gedcomx.org/Will`, /// A fact of a person's will.
		visit = `http://gedcomx.org/Visit`, /// A fact of a person's visit to a place different from the person's residence.
		yahrzeit = `http://gedcomx.org/Yahrzeit`, /// A fact of a person's _yahrzeit_ date.  A person's yahrzeit is the anniversary of their death as measured by the Hebrew calendar.
		annulment = `http://gedcomx.org/Annulment`, /// The fact of an annulment of a marriage.
		commonLawMarriage = `http://gedcomx.org/CommonLawMarriage`, /// The fact of a marriage by common law.
		civilUnion = `http://gedcomx.org/CivilUnion`, /// The fact of a civil union of a couple.
		domesticPartnership = `http://gedcomx.org/DomesticPartnership`, /// The fact of a domestic partnership of a couple.
		divorce = `http://gedcomx.org/Divorce`, /// The fact of a divorce of a couple.
		divorceFiling = `http://gedcomx.org/DivorceFiling`, /// The fact of a filing for divorce.
		engagement = `http://gedcomx.org/Engagement`, /// The fact of an engagement to be married.
		marriage = `http://gedcomx.org/Marriage`, /// The fact of a marriage.
		marriageBanns = `http://gedcomx.org/MarriageBanns`, /// The fact of a marriage banns.
		marriageContract = `http://gedcomx.org/MarriageContract`, /// The fact of a marriage contract.
		marriageLicense = `http://gedcomx.org/MarriageLicense`, /// The fact of a marriage license.
		marriageNotice = `http://gedcomx.org/MarriageNotice`, /// The fact of a marriage notice.
		separation = `http://gedcomx.org/Separation`, /// A fact of a couple's separation.
		adoptiveParent = `http://gedcomx.org/AdoptiveParent`, /// A fact about an adoptive relationship between a parent and a child.
		biologicalParent = `http://gedcomx.org/BiologicalParent`, /// A fact about the biological relationship between a parent and a child.
		fosterParent = `http://gedcomx.org/FosterParent`, /// A fact about a foster relationship between a foster parent and a child.
		guardianParent = `http://gedcomx.org/GuardianParent`, /// A fact about a legal guardianship between a parent and a child.
		stepParent = `http://gedcomx.org/StepParent`, /// A fact about the step relationship between a parent and a child.
		sociologicalParent = `http://gedcomx.org/SociologicalParent`, /// A fact about a sociological relationship between a parent and a child, but not definable in typical legal or biological terms.
		surrogateParent = `http://gedcomx.org/SurrogateParent`, /// A fact about a pregnancy surrogate relationship between a parent and a child.
	}
	enum QualifierTypes : Enum {
		age = `http://gedcomx.org/Age`, /// The age of a person at the event described by the fact.
		cause = `http://gedcomx.org/Cause`, /// The cause of the fact, such as the cause of death.
		religion = `http://gedcomx.org/Religion`, /// The religion associated with a religious event such as a baptism or excommunication.
	}
}

class EventRole : Conclusion {
	enum identifier = `http://gedcomx.org/v1/EventRole`;
	@Prop Person.Ptr person;
	@Attr Maybe!Enum type; 
	@Prop @Wrapped Maybe!string details;

	mixin addToXML!();

	enum Type : Enum {
		principal = `http://gedcomx.org/Principal`, /// The person is the principal person of the event. For example, the principal of a birth event is the person that was born.
		participant = `http://gedcomx.org/Participant`, /// A participant in the event.
		official = `http://gedcomx.org/Official`, /// A person officiating the event.
		witness = `http://gedcomx.org/Witness`, /// A witness of the event.
	}
}

class Date {
	enum identifier = `http://gedcomx.org/v1/Date`;
	@Prop @Wrapped Maybe!string original;
	@Prop @Wrapped Maybe!FormalDate formal;
	mixin addToXML!();
}

class PlaceReference {
	enum identifier = `http://gedcomx.org/v1/PlaceReference`;
	@Prop @Wrapped Maybe!string original;
	@Attr @Named(`description`) Maybe!(PlaceDescription.Ptr) descriptionRef;
	mixin addToXML!();
}

class NamePart {
	enum identifier = `http://gedcomx.org/v1/NamePart`;
	@Attr Maybe!Enum type;
	@Attr string value;
	@Prop @Named(`qualifier`) Qualifier[] qualifiers;

	mixin addToXML!();

	enum Type : Enum {
		prefix = `http://gedcomx.org/Prefix`, /// A name prefix. 
		suffix = `http://gedcomx.org/Suffix`, /// A name suffix. 
		given =  `http://gedcomx.org/Given`, /// A given name. 
		surname =`http://gedcomx.org/Surname`, /// A surname. 
	}
	enum QualifierTypes : Enum {
		title = `http://gedcomx.org/Title`, /// A designation for honorifics (e.g. Dr., Rev., His Majesty, Haji), ranks (e.g. Colonel, General, Knight, Esquire), positions (e.g. Count, Chief, Father, King) or other titles (e.g., PhD, MD). Name part qualifiers of type `Title` SHOULD NOT provide a value.
		primary = `http://gedcomx.org/Primary`, /// A designation for the name of most prominent in importance among the names of that type (e.g., the primary given name). Name part qualifiers of type `Primary` SHOULD NOT provide a value.
		secondary = `http://gedcomx.org/Secondary`, /// A designation for a name that is not primary in its importance among the names of that type (e.g., a secondary given name). Name part qualifiers of type `Secondary` SHOULD NOT provide a value.
		middle = `http://gedcomx.org/Middle`, /// A designation useful for cultures that designate a middle name that is distinct from a given name and a surname. Name part qualifiers of type `Middle` SHOULD NOT provide a value.
		familiar = `http://gedcomx.org/Familiar`, /// A designation for one's familiar name. Name part qualifiers of type `Familiar` SHOULD NOT provide a value.
		religious = `http://gedcomx.org/Religious`, /// A designation for a name given for religious purposes. Name part qualifiers of type `Religious` SHOULD NOT provide a value.
		family = `http://gedcomx.org/Family`, /// A name that associates a person with a group, such as a clan, tribe, or patriarchal hierarchy. Name part qualifiers of type `Family` SHOULD NOT provide a value.
		maiden = `http://gedcomx.org/Maiden`, /// A designation given by women to their original surname after they adopt a new surname upon marriage. Name part qualifiers of type `Maiden` SHOULD NOT provide a value.
		patronymic = `http://gedcomx.org/Patronymic`, /// A name derived from a father or paternal ancestor. Name part qualifiers of type `Patronymic` SHOULD NOT provide a value.
		matronymic = `http://gedcomx.org/Matronymic`, /// A name derived from a mother or maternal ancestor. Name part qualifiers of type `Matronymic` SHOULD NOT provide a value.
		geographic = `http://gedcomx.org/Geographic`, /// A name derived from associated geography. Name part qualifiers of type `Geographic` SHOULD NOT provide a value.
		occupational = `http://gedcomx.org/Occupational`, /// A name derived from one's occupation. Name part qualifiers of type `Occupational` SHOULD NOT provide a value.
		characteristic = `http://gedcomx.org/Characteristic`, /// A name derived from a characteristic. Name part qualifiers of type `Characteristic` SHOULD NOT provide a value.
		postnom = `http://gedcomx.org/Postnom`, /// A name mandated by law for populations from Congo Free State / Belgian Congo / Congo / Democratic Republic of Congo (formerly Zaire). Name part qualifiers of type `Postnom` SHOULD NOT provide a value.
		particle = `http://gedcomx.org/Particle`, /// A grammatical designation for articles (a, the, dem, las, el, etc.), prepositions (of, from, aus, zu, op, etc.), initials, annotations (e.g. twin, wife of, infant, unknown), comparators (e.g. Junior, Senior, younger, little), ordinals (e.g. III, eighth), descendancy words (e.g. ben, ibn, bat, bin, bint, bar), and conjunctions (e.g. and, or, nee, ou, y, o, ne, &amp;). Name part qualifiers of type `Particle` SHOULD NOT provide a value.
		rootName = `http://gedcomx.org/RootName`, /// The "root" of a name part as distinguished from prefixes or suffixes. For example, the root of the Polish name "Wilkówna" is "Wilk". A `RootName` qualifier MUST provide a `value` property.
	}
}

class NameForm {
	enum identifier = `http://gedcomx.org/v1/NameForm`;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
	@Prop @Wrapped Maybe!string fullText;
	@Prop @Named(`part`) NamePart[] parts;
	mixin addToXML!();
}

struct Qualifier {
	enum identifier = `http://gedcomx.org/v1/Qualifier`;
	@Attr Enum name;
	@Prop @FlatContent Maybe!string value;
	mixin addToXML!();
}

class Coverage {
	enum identifier = `http://gedcomx.org/v1/Coverage`;
	@Prop Maybe!PlaceReference spatial;
	@Prop Maybe!Date temporal;
	mixin addToXML!();
}


/// The `gx:Gedcomx` XML type is used as a container for a set of GEDCOM X data.
@Named(`gedcomx`)
@ExtraAttr(`xmlns`, `http://gedcomx.org/v1/`)
class Gedcomx {
	enum identifier = `http://gedcomx.org/v1/Gedcomx`;
	@Attr Maybe!string id;
	@Attr @Named(`xml:lang`) Maybe!LocaleTag lang;
	@Prop Maybe!Attribution attribution;
	@Prop @Named(`person`) Person[] persons;
	@Prop @Named(`relationship`) Relationship[] relationships;
	@Prop @Named(`sourceDescription`) SourceDescription[] sourceDescriptions;
	@Prop @Named(`agent`) Agent[] agents;
	@Prop @Named(`event`) Event[] events;
	@Prop @Named(`document`) Document[] documents;
	@Attr Maybe!(SourceDescription.Ptr) description;

	mixin addToXML!();
}

