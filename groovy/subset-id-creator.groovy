import groovy.text.XmlTemplateEngine
import groovy.xml.*

// Creating the Output File
def outputFile = new File("etc/output.xml")
// Re-create file
if(outputFile.exists()){
	println "Deleting ${outputFile.path} (${outputFile.absolutePath})..."
	outputFile.delete()
} 

def engine = new groovy.text.SimpleTemplateEngine()
def xmlStr = '''<entry>
    <key>$subsetId</key>
    <value>R</value>
</entry>'''

def xmlEles = []
new File("etc/subset-ids.csv").each{
    def binding = ["subsetId":it]
    xmlEles << engine.createTemplate(xmlStr).make(binding).toString() // Returns string representation of the XML
}

// Output the xmlElements
xmlEles.each {
    println it
}

/*
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
*/

// Write the results to output file
//outputFile << xmlOutput