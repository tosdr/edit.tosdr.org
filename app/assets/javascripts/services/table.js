$(".services.index").ready(function() {
  function compareServiceClassification(elementA, elementB) {
    if (
      !['A', 'B', 'C', 'D', 'E', 'F', 'N/A'].includes(elementA.dataset.classification)
      || !['A', 'B', 'C', 'D', 'E', 'F', 'N/A'].includes(elementB.dataset.classification)
    ) {
      return 0;
    }
    if (elementA.dataset.classification === elementB.dataset.classification) {
      return 0;
    }

    // Both do not have the same classification, so if one is good, that one is better:
    if (elementA.dataset.classification === 'A') {
      return -1;
    }
    if (elementB.dataset.classification === 'A') {
      return 1;
    }
    // Both do not have the same classification, and neither is good, so if one is neutral, that one is better:
    if (elementA.dataset.classification === 'B') {
      return -1;
    }
    if (elementB.dataset.classification === 'B') {
      return 1;
    }
    // Both do not have the same classification, and neither is good or neutral, so if one is bad, the other is a blocker:
    if (elementA.dataset.classification === 'C') {
      return -1;
    }
    if (elementB.dataset.classification === 'C') {
      return 1;
    }
    if (elementA.dataset.classification === 'D') {
      return -1;
    }
    if (elementB.dataset.classification === 'D') {
      return 1;
    }
    if (elementA.dataset.classification === 'E') {
      return -1;
    }
    if (elementB.dataset.classification === 'E') {
      return 1;
    }
    if (elementA.dataset.classification === 'F') {
      return -1;
    }
    if (elementB.dataset.classification === 'F') {
      return 1;
    }
    if (elementA.dataset.classification === 'N/A') {
      return -1;
    }
    if (elementB.dataset.classification === 'N/A') {
      return 1;
    }
  }

  document.getElementById('orderByService').addEventListener("click", (event) => {
    event.preventDefault();
    let elems =  document.getElementsByClassName("toSort");
    // convert nodelist to array
    var array = [];
    for (var i = 0; i < elems.length; i++) {
      array[i] = elems[i];
    }

    // perform sort depending on classname
    if(event.currentTarget.className=="btn btn-success"){
      array.sort((a, b) => compareServiceClassification(b, a));
      event.currentTarget.classList.remove("btn-success");
      event.currentTarget.classList.add("btn-danger");
    }
    else if(event.currentTarget.className== "btn btn-danger"){
      array.sort(compareServiceClassification);
      event.currentTarget.classList.remove("btn-danger");
      event.currentTarget.classList.add("btn-success");
    }
    // join the array back into HTML
    var output = "";
    for (var i = 0; i < array.length; i++) {
      output += array[i].outerHTML;
    }
    // append output to div 'points-table-container'
    document.getElementById('myTableBody').innerHTML = output;
  });
})
