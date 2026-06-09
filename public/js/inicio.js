// Configuración global de Chart.js
Chart.defaults.font.family = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
Chart.defaults.color = '#8b9b93';

// Colores de la paleta
const colors = {
    primary: '#4d2308',
    secondary: '#362419',
    neutral: '#cfcfcd',
    success: '#4CAF50',
    warning: '#FF9800',
    info: '#2196F3'
};

// Gráfico de Ventas del Día (Línea)
const salesCtx = document.getElementById('salesChart').getContext('2d');
const salesGradient = salesCtx.createLinearGradient(0, 0, 0, 250);
salesGradient.addColorStop(0, 'rgba(77, 35, 8, 0.3)');
salesGradient.addColorStop(1, 'rgba(77, 35, 8, 0)');

new Chart(salesCtx, {
    type: 'line',
    data: {
        labels: ['8am', '9am', '10am', '11am', '12pm', '1pm', '2pm', '3pm', '4pm', '5pm'],
        datasets: [{
            label: 'Ventas ($)',
            data: [120, 280, 450, 620, 890, 750, 580, 720, 950, 680],
            borderColor: colors.primary,
            backgroundColor: salesGradient,
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: colors.primary,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 5,
            pointHoverRadius: 7
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                backgroundColor: colors.secondary,
                titleColor: '#fff',
                bodyColor: '#fff',
                padding: 12,
                cornerRadius: 8,
                callbacks: {
                    label: function (context) {
                        return '$' + context.parsed.y;
                    }
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(207, 207, 205, 0.3)',
                    drawBorder: false
                },
                ticks: {
                    callback: function (value) {
                        return '$' + value;
                    }
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        }
    }
});

// Gráfico de Productos Más Vendidos (Doughnut)
const productsCtx = document.getElementById('productsChart').getContext('2d');
new Chart(productsCtx, {
    type: 'doughnut',
    data: {
        labels: ['Cappuccino', 'Espresso', 'Latte Frío', 'Croissant', 'Muffin'],
        datasets: [{
            data: [45, 38, 32, 28, 22],
            backgroundColor: [
                colors.primary,
                colors.secondary,
                colors.info,
                colors.warning,
                colors.success
            ],
            borderWidth: 0,
            hoverOffset: 8
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '65%',
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 16,
                    usePointStyle: true,
                    pointStyle: 'circle',
                    font: {
                        size: 12
                    }
                }
            },
            tooltip: {
                backgroundColor: colors.secondary,
                titleColor: '#fff',
                bodyColor: '#fff',
                padding: 12,
                cornerRadius: 8,
                callbacks: {
                    label: function (context) {
                        return context.label + ': ' + context.parsed + ' vendidos';
                    }
                }
            }
        }
    }
});