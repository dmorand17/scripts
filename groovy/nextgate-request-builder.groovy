import groovy.text.XmlTemplateEngine
import groovy.xml.*

final def NGV9NS = "http://person.webservice.index.mm.nextgate.com/"
final def NGV8NS = "http://webservice.index.mdm.sun.com/"

def buildNextGateRequest(member,namespace){
	/* 
	<web:executeMatchUpdate xmlns:web="http://person.webservice.index.mm.nextgate.com/">
         <!--Optional:-->
         <sysObjBean>
            <localId>$localId</localId>
            <person>
               <DOB>$dob</DOB>
               <firstName>$firstName</firstName>
               <gender>$gender</gender>
               <lastName>$lastName</lastName>
            </person>
            <systemCode>$systemCode</systemCode>
         </sysObjBean>
      </web:executeMatchUpdate>
	  */
	/*
	def xml = '''<users xmlns:gsp='http://groovy.codehaus.org/2005/gsp'>
		<gsp:scriptlet>users.each {</gsp:scriptlet>
			<user id="${it.id}"><gsp:expression>it.name</gsp:expression></user>
		<gsp:scriptlet>}</gsp:scriptlet>
	</users>'''
	*/
	
	def engine = new groovy.text.SimpleTemplateEngine()
	def nextGateRequest = '''<web:executeMatchUpdate xmlns:web="$namespace">
         <callerInfo/>
		 <sysObjBean>
            <localId>$localId</localId>
            <person>
               <DOB>$dob</DOB>
               <firstName>$firstName</firstName>
               <gender>$gender</gender>
               <lastName>$lastName</lastName>
            </person>
            <systemCode>$systemCode</systemCode>
         </sysObjBean>
      </web:executeMatchUpdate>'''
	
	def binding = ["localId":member.id
					,"dob": member.date_of_birth
					,"firstName": member.first_name
					,"lastName": member.last_name
					,"gender": member.gender
					,"systemCode": member.system_code
					,"namespace":namespace]

	return engine.createTemplate(nextGateRequest).make(binding).toString() // Returns string representation of the XML
}

def version = args[0] // v9 or v8

// Creating the Output File
def ngOutputFile = new File("etc/ngOutput.xml")
// Re-create file
if(ngOutputFile.exists()){
	println "Deleting ${ngOutputFile.path} (${ngOutputFile.absolutePath})..."
	ngOutputFile.delete()
} 

def members = []
// Open delimited file
new File("etc/members.csv").splitEachLine("\\|") {fields ->
  members << new Expando(id: fields[0]
				,last_name: fields[1]
				,first_name: fields[2]
				,gender: fields[3]
				,date_of_birth: Date.parse("dd-MMM-yy",fields[4]).format("MM/dd/yyyy")
				,system_code:"HZN")
}

def namespace = null
if (version.equalsIgnoreCase("v8")){
	namespace = NGV8NS
} else if (version.equalsIgnoreCase("v9")){
	namespace = NGV9NS
}

def nextGateRequests = [] // store list of nextgaterequests
members.each{member ->
	def ngRequest = buildNextGateRequest(member,namespace)
	nextGateRequests << ngRequest
}

// XML Formatting
def xmlOutput = new StringWriter()
def xmlNodePrinter = new XmlNodePrinter(new PrintWriter(xmlOutput))
xmlNodePrinter.with {
  preserveWhitespace = true
  expandEmptyElements = false
  quote = "'" // Use single quote for attributes
}

println "Writing ${nextGateRequests.size} entries..."
// Iterate over the NextGate requests, and pretty print
nextGateRequests.each{req ->
	def outputNode = new XmlParser().parseText(req) // Build Node object
	xmlNodePrinter.print(outputNode)
	xmlOutput.print("\n")
}

// Write the results to output file
ngOutputFile << xmlOutput