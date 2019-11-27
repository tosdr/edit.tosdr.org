$(".services.index").ready(function() {
  const grades = ['A', 'B', 'C', 'D', 'E', 'F', 'N/A'];
  function compareServiceClassification(elementA, elementB) {
    const classA = elementA.dataset.classification;
    const classB = elementB.dataset.classification;
    if (!grades.includes(classA) || !grades.includes(classB)) {
      return 0;
    }
    if (classA === classB) {
      return 0;
    }
    for (grade in grades) {
      if (classA === grade) {
        return -1;
      }
      if (classB === grade) {
        return 1;
      }
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
