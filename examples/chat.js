var USER = '';
var CHANNEL = 'test_msgs';

var channels = {};

function sendMessage(text) {
  if(USER == '') {
    console.error('No user');
  } else {
    Pages.callback("send", [CHANNEL, USER, text]);
  }
}

function onMessage(channel, user, message) {
  var title = document.createElement('span');
  title.className = 'card-title';
  title.textContent = user;

  var text = document.createElement('p');
  text.textContent = message;

  var content = document.createElement('div');
  content.className = 'card-content white-text';
  content.appendChild(title);
  content.appendChild(text);

  var card = document.createElement('div');
  card.className = 'card teal lighten-1';
  card.appendChild(content);

  var col = document.createElement('div');
  col.className = 'col s6';
  col.appendChild(card);

  var row = document.createElement('div');
  row.className = 'row';
  row.style = 'margin-bottom: 0';
  if(USER == user) {
    var c = document.createElement('div');
    c.className = 'col s6';
    row.appendChild(c);
  }
  row.appendChild(col);

  var log = document.getElementById("log");
  log.appendChild(row);
  log.scrollTop = log.scrollHeight;
}
