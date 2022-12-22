import Chart from 'chart.js/auto';

const StatsDashboardChart = {
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

    this.handleEvent("stats_dashboard:update_chart", (data) => {
      this.chart.data = data;
      this.chart.update();
    })
  }
};

export default StatsDashboardChart;
