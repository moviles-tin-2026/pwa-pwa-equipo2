document.addEventListener('DOMContentLoaded', () => {
  // 1. Lógica de los botones Semanal/Mensual
  const toggleBtns = document.querySelectorAll('.toggle-btn');
  toggleBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      toggleBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      // Aquí podrías cambiar los datos y llamar a drawChart() de nuevo
    });
  });

  // 2. Lógica de la Gráfica con Canvas
  const canvas = document.getElementById('salesChart');
  const ctx = canvas.getContext('2d');

  // Datos de ejemplo (Los valores coinciden visualmente con el pico del jueves de $1,240)
  const chartData = {
    labels: ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'],
    values: [750, 920, 850, 1240, 1050, 1300, 1150],
    activeDayIndex: 3 // 'Jue' es el índice 3
  };

  function drawChart() {
    // Ajustar resolución para pantallas de alta densidad (Retina displays)
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);

    const width = rect.width;
    const height = rect.height;

    // Márgenes internos de la gráfica
    const padding = { top: 10, right: 10, bottom: 30, left: 10 };
    const chartWidth = width - padding.left - padding.right;
    const chartHeight = height - padding.top - padding.bottom;

    // Limpiar canvas en cada redibujado
    ctx.clearRect(0, 0, width, height);

    // Calcular valores máximos para escalar la gráfica
    const maxVal = 1500; 

    // --- A. Dibujar líneas de cuadrícula horizontales ---
    const gridLines = 4;
    ctx.strokeStyle = '#EEDCD3'; // Color var(--border-color)
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < gridLines; i++) {
      const y = padding.top + (chartHeight / (gridLines - 1)) * i;
      ctx.moveTo(padding.left, y);
      ctx.lineTo(width - padding.right, y);
    }
    ctx.stroke();

    // Calcular coordenadas X e Y para cada punto de datos
    const stepX = chartWidth / (chartData.values.length - 1);
    const points = chartData.values.map((val, index) => {
      const x = padding.left + (stepX * index);
      const y = padding.top + chartHeight - ((val / maxVal) * chartHeight);
      return { x, y };
    });

    // --- B. Dibujar Área con Gradiente ---
    const gradient = ctx.createLinearGradient(0, padding.top, 0, height - padding.bottom);
    gradient.addColorStop(0, 'rgba(77, 35, 8, 0.15)'); // var(--primary) con opacidad
    gradient.addColorStop(1, 'rgba(77, 35, 8, 0)'); // Transparente abajo

    ctx.beginPath();
    ctx.moveTo(points[0].x, height - padding.bottom); // Esquina inferior izquierda
    points.forEach(p => ctx.lineTo(p.x, p.y));        // Trazar línea de datos
    ctx.lineTo(points[points.length - 1].x, height - padding.bottom); // Esquina inferior derecha
    ctx.fillStyle = gradient;
    ctx.fill();

    // --- C. Dibujar Línea de Tendencia ---
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    points.forEach(p => ctx.lineTo(p.x, p.y));
    ctx.strokeStyle = '#4D2308'; // var(--primary)
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.stroke();

    // --- D. Dibujar Punto Activo (Jueves) ---
    const activePoint = points[chartData.activeDayIndex];
    ctx.beginPath();
    ctx.arc(activePoint.x, activePoint.y, 5, 0, Math.PI * 2);
    ctx.fillStyle = '#FCF5F3'; // Color de fondo
    ctx.fill();
    ctx.lineWidth = 2.5;
    ctx.strokeStyle = '#4D2308';
    ctx.stroke();

    // --- E. Dibujar Textos del Eje X ---
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    
    chartData.labels.forEach((label, index) => {
      const x = padding.left + (stepX * index);
      const y = height - padding.bottom + 12;
      
      if (index === chartData.activeDayIndex) {
        ctx.fillStyle = '#4D2308'; // Texto activo
        ctx.font = 'bold 12px Inter, sans-serif';
      } else {
        ctx.fillStyle = '#7E7571'; // Texto muteado
        ctx.font = '12px Inter, sans-serif';
      }
      ctx.fillText(label, x, y);
    });
  }

  // Dibujar al cargar
  drawChart();

  // Redibujar al cambiar el tamaño de la ventana (Hace la gráfica responsiva)
  window.addEventListener('resize', drawChart);
});