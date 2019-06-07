document.getElementById('point_case_id').addEventListener('change', function() {

let id = document.getElementById('point_case_id').selectedIndex;

let title = document.getElementById('point_case_id').options[id].dataset.title;
document.querySelectorAll("input[name='point[title]']")[0].setAttribute("value", title);

let desc = document.getElementById('point_case_id').options[id].dataset.descrip;
document.querySelectorAll("textarea[name='point[analysis]']")[0].setAttribute("value", desc);

let rating = document.getElementById('point_case_id').options[id].dataset.rating;

if (rating === "blocker") {
  var to_check = 1;
} else if (rating === "bad") {
  var to_check = 2;
} else if (rating === "neutral") {
  var to_check = 3;
} else if (rating === "good") {
  var to_check = 4;
}

document.querySelectorAll("input[name='point[rating]']")[to_check].checked = true;

});
