import org.apache.commons.cli.Option

/*
*   input file should be a separated file in the following format:
*   "subset-id":438000010135,"next-item":value
*/

/*
 static void exitWithMessage(String message) {
    System.err.println(message)
    cli.usage()
    System.exit(1)
  }
*/

def getEngine(engine){
    // ["xml","simple"].contains(opt.e) || exitWithMessage('Unknown engine ' + opt.e)
    engine = null
    switch(engine){
        case "xml":
            engine = new groovy.text.XmlTemplateEngine()
            break
        case "simple":
            engine = new groovy.text.SimpleTemplateEngine()
        default:
            // invalid engine sent
            break
    }

    return engine
}

def cli = new CliBuilder(usage: 'TemplateBuilder.groovy [-h] -t <template-file> [-o output-file] [-e engine]')
// Create the list of options.
cli.with {
    h longOpt: 'help', 'Show usage information', required: false
    t longOpt: 'template-file','Template file to be used for building output file', args: 1, required: true
    b longOpt: 'bindings','Bindings to be used for mapping input-file into template-file', args: Option.UNLIMITED_VALUES, valueSeparator: ';', required: true
    i longOpt: 'input-file','Input file to be used for sourcing the template', args: 1, required: true
    o longOpt: 'output-file','Optional: Output file containing results.  Defaults to output.txt', args: 1, required: false
    e longOpt: 'engine','Optional: Template engine to be used ("xml","simple").  Defaults to SimpleTemplateEngine', args: 1, required: false
}
    
def opt = cli.parse(args)

if (!opt) return // No options, return
if (opt.h) cli.usage() // Show usage text when -h or --help option is used.

def templateFile = opt.'template-file'
def inputFile = opt.'input-file'
def bindings = opt.bs
def outputFile = opt.o ? opt.o : "output.txt"
def engine = opt.e ? getEngine(opt.e) : new groovy.text.SimpleTemplateEngine();

println "Template: ${templateFile}\nInputFile: ${inputFile}\noutputFile: ${outputFile}\nengine: ${engine}\nbinding: ${bindings}"

// Iterate over the csv 

new File(inputFile).splitEachLine(";"){ fields ->
    // ensure that the length of fields matches the number of bindings
    
    if (fields.size() != bindings.size()){
        println "Incorrect number of fields: ${fields}"
        return
    }
    members << new Expando(id: fields[0]
				,last_name: fields[1]

}

/*
def templateEles = new [] // array to hold the template
new File(inputFile).each{
    def binding = ["subsetId":it]
    templateEles << engine.createTemplate(new File(templateFile).text).make(binding).toString() // Returns string representation of the XML
}
*/