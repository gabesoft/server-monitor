(function() {
  window.onload = function() {
    const ws  = new WebSocket(jsRoutes.controllers.Application.stream().webSocketURL());
    const connectionTimeout = 30 * 60 * 1000;

    function getProcEl(proc, name) {
      return document.querySelector('.' + proc.name + ' .' + name);
    }

    function setValue(proc, name, value) {
      getProcEl(proc, name).textContent = value;
    }

    function setAttribute(proc, name, attrName, attrValue) {
      getProcEl(proc, name).setAttribute(attrName, attrValue);
    }

    function toggleClass(proc, name, cls, add)  {
      const el = getProcEl(proc, name);
      const fn = add ? 'add' : 'remove';
      el.classList[fn](cls);
    }

    function padWithZeros(num) {
      return num < 10 ? '0' + num : num;
    }

    function formatDate(date) {
      var day = padWithZeros(date.getDate());
      var month = padWithZeros(date.getMonth());
      var year = date.getFullYear();
      var hours = padWithZeros(date.getHours());
      var minutes = padWithZeros(date.getMinutes());
      return day + '/' + month + '/' + year + ' ' + hours + ':' + minutes;
    }

    function refreshProcess(proc) {
      console.log(proc.status);
      if (proc.status.error) {
        setValue(proc, 'status', 'down');
        setAttribute(proc, 'status', 'title', proc.status.error);
        toggleClass(proc, 'status', 'up', false);
        toggleClass(proc, 'status', 'down', true);
      } else {
        setValue(proc, 'pid', proc.status.pid);
        setValue(proc, 'mem', proc.status.mem + ' %');
        setValue(proc, 'cpu', proc.status.cpu + ' %');
        setValue(proc, 'start-date', formatDate(new Date(proc.status.stime)));
        setValue(proc, 'status', 'up');
        toggleClass(proc, 'status', 'up', true);
        toggleClass(proc, 'status', 'down', false);
        setAttribute(proc, 'status', 'title');
      }
    }

    ws.onopen = function() {
      console.log('socket open');
      ws.send(JSON.stringify({ type: 'readStatus' }));
      setTimeout(function() {
        ws.close();
      }, connectionTimeout);
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
