$(function() {
  function getDataElement(selectionNode) {
    if (
      !selectionNode.parentElement ||
      !selectionNode.parentElement.dataset ||
      !selectionNode.parentElement.dataset.documentId
    ) {
      // The document element usually is the parent element of nodes in the selection.
      // However, since there are also "hidden" nodes (containing HTML of the scraped documents),
      // we might have to look at the parent of the parent.
      // (Of course this could also be done recursively, but then we'd be traversing the DOM all the way up.)
      if(
        !selectionNode.parentElement ||
        !selectionNode.parentElement.parentElement ||
        !selectionNode.parentElement.parentElement.dataset ||
        !selectionNode.parentElement.parentElement.dataset.documentId
      ) {
        return null;
      }
      return selectionNode.parentElement.parentElement;
    }

    return selectionNode.parentElement;
  }

  function getDocumentData(selectionNode) {
    const dataElement = getDataElement(selectionNode);

    return dataElement ? dataElement.dataset : null;
  }

  function normaliseSpecialChars(withPotentialSpecialChars){
    return withPotentialSpecialChars
      // On the page (and hence in our selection), all whitespace is rendered as spaces.
      // (Don't ask me how long I spent debugging non-breaking spaces :S)
      // We convert them to spaces in the document as well, to be able to find the selected text there.
      // Since the actual quote is stored in the database as a text range, this doesn't matter,
      // as long as the amount of characters in the selection is accurate.
      .replace(/\s/g, ' ')
      // UTF-16 surrogate pairs take up the space of *two* characters, which means that the position
      // returned by `indexOf` will be off compared to when doing so in Ruby (which treats them as
      // single characters).
      // Therefore, we replace them with a space (a single character).
      // Approach based on https://stackoverflow.com/a/4885062
      .replace(/[\uD800-\uDFFF]./, ' ');
  }

  function setFormToSelection() {
    const selection = window.getSelection()
    const documentContent = normaliseSpecialChars(getDataElement(selection.anchorNode).parentElement.dataset.content);
    const documentData = getDocumentData(selection.anchorNode);

    // Convert all whitespace in the selection to spaces for consistency with the document.
    const quotedText = normaliseSpecialChars(selection.toString());
    const selectionStart = documentContent.indexOf(quotedText);
    console.log({ selectionStart, quotedText, documentContent });
    if (selectionStart == -1) {
      panic();
    }
    const quoteForm = document.getElementById('quoteForm');
    quoteForm.elements.document_id.value =  documentData.documentId;
    quoteForm.elements.quoteRev.value =  documentData.revision;
    quoteForm.elements.quoteStart.value = selectionStart
    quoteForm.elements.quoteEnd.value = selectionStart + quotedText.length
  }

  function linkSelectionToCase(caseDropdownSubmitEvent) {
    caseDropdownSubmitEvent.preventDefault();

    const caseDropdown = document.querySelector('#caseDropdown select');
    const caseId = caseDropdown.options[caseDropdown.selectedIndex].dataset.caseId;

    const quoteForm = document.getElementById('quoteForm');
    quoteForm.elements.quoteCaseId.value = caseId
    setFormToSelection();

    quoteForm.submit();
  }

  function linkSelectionToPoint(pointFormSubmitEvent) {
    pointFormSubmitEvent.preventDefault();

    setFormToSelection();

    const quoteForm = document.getElementById('quoteForm');
    quoteForm.submit();
  }

  const toast = document.getElementById('caseToast') || document.getElementById('pointToast');

  if (toast && toast.id === 'caseToast') {
    const caseDropdown = document.getElementById('caseDropdown');
    if (caseDropdown) { caseDropdown.addEventListener('submit', linkSelectionToCase); }
  } else {
    const pointForm = document.getElementById('pointForm')
    if (pointForm) { pointForm.addEventListener('submit', linkSelectionToPoint); }
  }

  document.addEventListener('selectionchange', () => {
    const selection = document.getSelection();

    // Make sure the current selection is part of one of the documents:
    if (
      selection.toString().length === 0 ||
      !getDataElement(selection.anchorNode) ||
      getDataElement(selection.anchorNode) !== getDataElement(selection.focusNode)
    ) {
      toast.classList.remove('withSelection');
      return;
    }

    // topOfPage is negative if we're scrolled down:
    const topOfPage = document.body.getBoundingClientRect().top;
    const selectionBottom = selection.getRangeAt(0).getBoundingClientRect().bottom - topOfPage;

    toast.style.top = (selectionBottom + 10).toString() + 'px';
    toast.classList.add('withSelection');
  });
});
