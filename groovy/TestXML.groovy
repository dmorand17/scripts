import groovy.xml.XmlUtil
import groovy.xml.QName


def xml = """
<books>
    <book>
        <title>One</title>
    </book>
    <book>
        <title>Two</title>
    </book>
    <publisher>Pub1</publisher>
    <publisher>Pub2</publisher>
</books>
"""

def books = new XmlParser().parseText(xml)
//println(XmlUtil.serialize(books))

// Modify book title one
books.book[0].title[0].value = "Testing"

println(XmlUtil.serialize(books))

// Remove all the publishers
def publishers = books.'*'.findAll{it.name() in ["publisher"]}*.replaceNode{}
//def publishers = books.'*'.findAll{it.name() in ["publisher"]}.each{it.replaceNode{}}
println(XmlUtil.serialize(books))

books.appendNode(
    new QName("","dataset")
    ,[:]
    ,"12345"
)

println(XmlUtil.serialize(books))

// Add new publishers
