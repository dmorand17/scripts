// your Groovy Code
import groovy.json.JsonSlurper
import groovy.xml.*

def printWithTime(msg){
	def now = new Date()
	println(now.format("YYYYMMdd HH:mm:ss") + "|${msg}")
}

def renderAuth(auth){
    return { 
        for (entry in auth) {
            //println "Handling ${entry}"
            switch(entry.value.getClass() ){
                case Map :
                    "${entry.key}" renderAuth( entry.value )
                    break
                case List:
                    entry.value.each { listEntry ->
                        "${entry.key}" renderAuth( listEntry )
                    }
                    break
                default :
                     "${entry.key}" "${entry.value}"
                break
            }
        }
    }
}      

printWithTime("Parsing ${jsonFile}")
//def auths = new JsonSlurper().parse(new FileReader(jsonFile))
def auths = new JsonSlurper().parse(new FileReader(jsonFile))
printWithTime "Parsing ${jsonFile} complete!"

def fileWriter = new File(globalMap.get("xmlFile")).newWriter()

def authsConverted = 0
auths.CaseLevel.each{auth ->
    def writer = new StringWriter()
    def builder = new MarkupBuilder(new IndentPrinter(new PrintWriter(writer),"",false))
    builder."CaseLevel"(renderAuth(auth))

    fileWriter.write(writer.toString() + "\n")
    authsConverted++
    
    authsConverted % 5000 == 0 ? printWithTime("Converted ${authsConverted} auths...") : null
}

printWithTime("Converted ${authsConverted} records")
printWithTime("Conversion complete!")

fileWriter.close()