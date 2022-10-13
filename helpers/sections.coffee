
delayedOnLoad = []
onDone = null
data = {}
nbrOfSectionsToLoad = -1
nbrOfSectionsLoaded = 0
lastSection = null

execute = (func) ->
  for section in data
    func section
  return
  
findPreviousPageBeforeInsertion = (section)->
  if section.pages.length
    return section.pages[section.pages.length - 1]
  if ! section.previous
    return null
  return findPreviousPageBeforeInsertion(section.previous)


findNextPageBeforeInsertion = (section)->      
  if ! section.next
    return null
  if section.next.pages[0]
    return section.next.pages[0]
  return findNextPageBeforeInsertion(section.next)

      
loadedOneSection = ()->
  nbrOfSectionsLoaded++
  console.log "loaded #{nbrOfSectionsLoaded} of #{nbrOfSectionsToLoad} sections"     
  if nbrOfSectionsLoaded == nbrOfSectionsToLoad   
    console.log("execution delayed code on sections") 
    for funcPairs in delayedOnLoad
      execute funcPairs.perSection
      if funcPairs.onEnd then funcPairs.onEnd()      
  return      

registerSection = (section) ->
  section.pages = []
  console.log "adding section " + section.id
  if lastSection
    section.previous = lastSection 
    lastSection.next = section
  else sections.head = section
  
  lastSection = section

  section.addPage = (page)->
    page.active = false
    page.section = this
    page.id = section.id + '.' + this.pages.length

    page.previous = findPreviousPageBeforeInsertion(section)
    if page.previous
      if page.previous.next #we have found the next page, otherwise it means it has not been loaded yet
        page.next = page.previous.next
        page.previous.next.previous = page
      page.previous.next = page
    else 
      page.next = findNextPageBeforeInsertion(section)
      if page.next
        # we know the next page had no previous, otherwise we'd have found it with findPreviousPageBeforeInsertion
        page.next.previous = page

    # maybe we should have chosen between javascript arrays and a couple of linked list to represent our data, instead of doing both :)
    page.destroy = ()->
      if page.next
        page.next.previous = page.previous
      if page.previous
        page.previous.next = page.next
      page.section.pages.splice(page.index,1)

    page.index = this.pages.push page  

  section.destroy = ()->
    if section.next
      section.next.previous = section.previous
    if section.previous
      section.previous.next = section.next
    delete data[section.id]

  data[section.id] = section
      


registerSectionData = (sectionData) ->
  section = sections.data[sectionData.id]
  if !section #this shouldn't happen, sections need to be registered before we call this function
  # for the client this function is "overriden" in sections.ng.coffee to handle the case when we've prerendered the markdown so we never get here.
    throw new Error("section #{sectionData.id} has not been registered.")
  else #we did not prerender the markdown on the server, and we registered all the sections on the client when processing it (the markdown),
  # so that they be correctly ordered (otherwise registering after fetching the md files asynchronously would result in random ordering)
    for key, value of sectionData 
      section[key]=value

  sections.loadedOneSection()
  return section
        
  

sections = { 
  data : data
  onLoad : (funcPerSection, onEnd) ->
    if nbrOfSectionsToLoad <= nbrOfSectionsLoaded
      execute funcPerSection
      if onEnd then onEnd()
      return
    delayedOnLoad.push {perSection:funcPerSection, onEnd:onEnd}      
    return
  registerSection
  registerSectionData
  loadedOneSection
  nbrOfSectionsToLoad: (nbr) ->       
    console.log "nbr of sections to load: #{nbr}"     
    nbrOfSectionsToLoad = nbr
    nbrOfSectionsLoaded = 0   
  isLoaded: ()->
    nbrOfSectionsToLoad == nbrOfSectionsLoaded
}
module.exports = sections