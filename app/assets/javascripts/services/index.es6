$(document).ready(function () {
  new Vue({
    el: '#dynamic-services-table',
    data () {
      return {
        search: '',
        loading: true,
        services: []
      }
    },
    methods: {
      fetchServices () {
        let self = this
        $.get(`/services/list_all`)
          .then((response) => {
            self.services = response
            self.loading = false
          })
      },

      sortServices (event) {
        let servicesToSort = this.services

        // perform sort depending on classname
        if (event.currentTarget.className=="btn btn-success") {
          servicesToSort = servicesToSort.sort((a, b) => this.compareServiceClassification(b, a));
          event.currentTarget.classList.remove("btn-success");
          this.services = servicesToSort
          event.currentTarget.classList.add("btn-danger");
        } else if (event.currentTarget.className== "btn btn-danger") {
          servicesToSort = servicesToSort.sort(this.compareServiceClassification);
          event.currentTarget.classList.remove("btn-danger");
          event.currentTarget.classList.add("btn-success");
          this.services = servicesToSort
        }
      },

      compareServiceClassification (elementA, elementB) {
        const classA = elementA.service.rating;
        const classB = elementB.service.rating;
        const grades = ['A', 'B', 'C', 'D', 'E', 'F', 'N/A'];

        if (!grades.includes(classA) || !grades.includes(classB)) {
          return 0;
        }

        if (classA === classB) {
          return 0;
        }

        let value
        grades.forEach(grade => {
          if (classA === grade) {
            value = -1;
          }
          if (classB === grade) {
            value = 1;
          }
        })
        return value
      }

    },
    computed: {
      filteredServices () {
        return this.services.filter((s) => {
          return s.service.name.toLowerCase().match(this.search.toLowerCase()) || s.service.url.toLowerCase().match(this.search.toLowerCase())
        })
      }
    },
    mounted () {
      this.services = this.fetchServices()
    }
  })
})
