import Chart from 'chart.js/auto';

export default {
  mounted() {
    this.chart = new Chart(this.el, {
      type: 'line',
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });

    this.handleEvent("update_chart", (data) => {
      this.chart.data = data;
      this.chart.update();
    })
  }
}
