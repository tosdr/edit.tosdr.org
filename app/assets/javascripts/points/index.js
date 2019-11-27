$(".points.index").ready(function() {
  function compareClassification(elementA, elementB) {
    if (
      !['good', 'neutral', 'bad', 'blocker'].includes(elementA.dataset.classification)
      || !['good', 'neutral', 'bad', 'blocker'].includes(elementB.dataset.classification)
    ) {
      return 0;
    }

    if (elementA.dataset.classification === elementB.dataset.classification) {
      return 0;
    }
    // Both do not have the same classification, so if one is good, that one is better:
    if (elementA.dataset.classification === 'good') {
      return -1;
    }
    if (elementB.dataset.classification === 'good') {
      return 1;
    }
    // Both do not have the same classification, and neither is good, so if one is neutral, that one is better:
    if (elementA.dataset.classification === 'neutral') {
      return -1;
    }
    if (elementB.dataset.classification === 'neutral') {
      return 1;
    }
    // Both do not have the same classification, and neither is good or neutral, so if one is bad, the other is a blocker:
    if (elementA.dataset.classification === 'bad') {
      return -1;
    }
    if (elementB.dataset.classification === 'bad') {
      return 1;
    }
  }

  document.getElementById('orderByPoint').addEventListener("click", (event) => {
    event.preventDefault();
    let elems =  document.getElementsByClassName("toSort");
    // convert nodelist to array
    var array = [];
    for (var i = 0; i < elems.length; i++) {
      array[i] = elems[i];
    }

    // perform sort depending on classname
    if(event.currentTarget.className=="btn btn-success"){
      array.sort((a, b) => compareClassification(b, a));
      event.currentTarget.classList.remove("btn-success");
      event.currentTarget.classList.add("btn-danger");
    }
    else if(event.currentTarget.className== "btn btn-danger"){
      array.sort(compareClassification);
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
});
