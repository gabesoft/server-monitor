(function() {
  window.onload = function() {
    const ws  = new WebSocket(jsRoutes.controllers.Application.stream().webSocketURL());

    function setValue(proc, name, value) {
      const el = document.querySelector('.' + proc.name + ' .' + name);
      el.textContent = value;
    }

    function refreshProcess(proc) {
      setValue(proc, 'pid', proc.status.pid);
      setValue(proc, 'mem', proc.status.mem);
      setValue(proc, 'cpu', proc.status.cpu);
      setValue(proc, 'start-date', new Date(proc.status.stime));
    }

    ws.onopen = function() {
      console.log('socket open');
      ws.send(JSON.stringify({ type: 'readStatus' }));
    };

    ws.onclose = function() {
      console.log('socket closed');
    };

    ws.onmessage = function(event) {
      const data = JSON.parse(event.data);
      data.status = JSON.parse(data.status);
      refreshProcess(data);
    };

    window.ws = ws;
  };
})();
