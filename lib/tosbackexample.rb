require_relative 'tosbackdoc'

# To run: $> ruby lib/tosbackexample.rb


# example data taken from https://github.com/tosdr/tosback2/blob/c96db88/rules/wikipedia.org.xml:
# -----------
# <sitename name="wikipedia.org">
#  <docname name="Privacy Policy">
#   <url name="https://wikimediafoundation.org/wiki/Privacy_policy" xpath="//*[@id='mw-content-text']" reviewed="true">
# [...]


doc = TOSBackDoc.new({
  url: "https://wikimediafoundation.org/wiki/Privacy_policy", # url.name
  xpath: "//*[@id='mw-content-text']" # url.xpath
})
doc.scrape
puts doc.newdata
