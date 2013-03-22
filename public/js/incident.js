
$(document).ready(function() {
    knownEvents = [];
    knownTasks = [];
    modalVisible = false;

    div = $('<div>');
    div.attr('id', 'loading');
    $('body').append(div);
    $('#loading').load('/html/loading.html');
    $('#loadingModal').modal({
        keyboard: false
    });

    $('#newEventBtn').click( function() {
        new_event_modal();
    });

    $('#newTaskBtn').click( function() {
        new_task_modal();
    });

    $("#timeline.filter").click( function() {
        getTimeline(team, incident, true);
    });

    $("#tasklist.filter").click( function() {
        getTasklist(team, incident, true);
    });

    getTimeline(team, incident, true);
    getTasklist(team, incident, true);

    var refreshId = setInterval(function() {
        if ( modalVisible == false ) {
            getTimeline(team, incident, false);
            getTasklist(team, incident, false);
        };
    }, 5000);

});


function getRelTime(thedate) {
    now = new Date();
    d = new Date(thedate);
    one_min = 60; 
    one_hour = 60*60;
    one_day = 60*60*24;
    date_diff = Math.floor(now.getTime() / 1000) - Math.floor(d.getTime() / 1000)
    if ( date_diff < 60 ) {
        ts = Math.ceil(date_diff) + " seconds ago";
    } else if ( date_diff / one_min <= 60 ) {         
        ts = Math.ceil(date_diff / one_min) +" min ago";
    } else if ( date_diff / one_hour <= 24 ) {
        ts = Math.ceil(date_diff / one_hour) + " hours ago";
    } else {
        ts = Math.ceil(date_diff / one_day) + " days ago";
    };
    return ts
}

function writeEvent(myEvent, index, ar) {
    if ($("#timeline.filter #" + myEvent['severity']).hasClass('active')) {
        console.debug("Writing event: " + myEvent['message']);
        myEvent['id'] = myEvent['timestamp'].toString().replace('.','');
        o = $('<div>');
        o.addClass(myEvent['severity']+'-timeline tlevent roundCorners');
        o.attr( 'id', myEvent['id']+"-event");
        timestamp = $('<div>');
        timestamp.addClass('superscript');
        timestamp.attr( 'title', new Date(myEvent['timestamp'] * 1000) );
        timestamp.text(getRelTime(myEvent['timestamp'] * 1000));
        o.append(timestamp);
        author = $('<bold>');
        author.addClass('timeline_author');
        author.text(myEvent['author']);
        o.append(author);
        message = $('<div>');
        message.addClass('timeline_message');
        if ( myEvent['message'].length > 140 ) {
            message.text(myEvent['message'].substring(0,140) + "...");
        } else {
            message.text(myEvent['message']);
        }
        o.append(message);

        gear = $('<div id="'+myEvent['id']+'" class="btn-group gear">' +
        '<a class="btn-mini dropdown-toggle" data-toggle="dropdown" href="#">' +
        '<i class="icon-cog"></i><span class="caret"></span></a>' + 
        '<ul class="dropdown-menu pull-right">' +
        '<li><a data-toggle="modal" data-target="#'+myEvent['id']+'-modal">View</a></li>' +
        '<li class="divider"></li>' +
        '<li>Set Severity Level</li>' + 
        '<li><a href="#" onclick="change_sev_event('+myEvent['timestamp']+', \'major\')">Major</a></li>' +
        '<li><a href="#" onclick="change_sev_event('+myEvent['timestamp']+', \'minor\')">Minor</a></li>' +
        '<li><a href="#" onclick="change_sev_event('+myEvent['timestamp']+', \'atomic\')">Atomic</a></li>' +
        '<li>Delete Event</li>' +
        '<li><a href="#" onclick="delete_event('+myEvent['timestamp']+')">Delete</a></li>' +
        '</ul>');

        o.append(gear);

        o.append(event_modal(myEvent));

        $("#timelineEvent").prepend(o);

        $('#'+myEvent['id']+'-sev #'+myEvent['severity']).button('toggle');

        newHeight=$('#timelineEvent').height() + 29;
        $("#vert_bar #major").height(newHeight);
        $("#vert_bar #minor").height(newHeight);
        $("#vert_bar #atomic").height(newHeight);
    };
}

function new_event_modal() {
    console.log('building new event modal');
    modal = $('<div>');
    modal.addClass('modal hide fade');
    modal.attr('id', 'new-event-modal');
    modal.attr('tabindex', '-1');
    modal.attr('role', 'dialog');
    modal.attr('aria-labelledby', 'New Timeline Event');
    modal.attr('aria-hidden', 'true');
    modalHeader = $('<div>');
    modalHeader.addClass('modal-header');
    modalHeader.append('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>');
    modalHeader.append('<h3>New Timeline Event</h3>');
    modal.append(modalHeader);
    modalBody = $('<div>');
    modalBody.addClass('modal-body');
    dl = $('<dl>');
    dl.addClass('dl-horizontal');
    dl.append('<dt>Author</dt><dd id="author"><input type="text" id="author-input" value="'+username+'"></dd>');
    sevBtns = $('<div>');
    sevBtns.addClass('btn-group');
    sevBtns.attr('data-toggle', 'buttons-radio');
    sevBtns.append('<button type="button" id="major" class="btn">Major</button>');
    sevBtns.append('<button type="button" id="minor" class="btn">Minor</button>');
    sevBtns.append('<button type="button" id="atomic" class="btn active">Atomic</button>');
    dl.append('<dt>Severity</dt><dd id="severity">'+sevBtns[0].outerHTML+'</dd>');
    dl.append('<dt>Message</dt><dd id="message"><textarea rows="3" type="text" id="message-input"></textarea></dd>');
    modalBody.append(dl);
    modal.append(modalBody);
    modalFooter = $('<div>');
    modalFooter.addClass('modal-footer');
    modalFooter.append('<a href="#" id="modal-close" class="btn" data-dismiss="modal">Cancel</a>');
    modalFooter.append('<a href="#" onclick="save_new_event()" id="modal-save" class="btn btn-primary">Save</a></div>');
    modal.append(modalFooter);
    $('#new-event-modal').replaceWith(modal);
    $('#new-event-modal').modal();
}

function event_modal(obj) {
    modal = $('<div>');
    modal.addClass('modal hide fade');
    modal.attr('id', obj['id']+'-modal');
    modal.attr('tabindex', '-1');
    modal.attr('role', 'dialog');
    modal.attr('aria-labelledby', 'Detailed View');
    modal.attr('aria-hidden', 'true');
    modal.attr('timestamp', obj['timestamp']);
    modalHeader = $('<div>');
    modalHeader.addClass('modal-header');
    modalHeader.append('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>');
    modalHeader.append('<h3>Detailed View</h3>');
    modalHeader.append('<a href="#" onclick="editable_event_modal(\''+obj['id']+'-modal\')" id="modal-edit" class="btn btn-primary" >Edit</a></div>');
    modal.append(modalHeader);
    modalBody = $('<div>');
    modalBody.addClass('modal-body');
    dl = $('<dl>');
    dl.addClass('dl-horizontal');
    dl.append('<dt>Timestamp</dt><dd id="timestamp">'+new Date(obj['timestamp'] * 1000)+'</dd><dt>');
    sevBtns = $('<div>');
    sevBtns.addClass('btn-group');
    sevBtns.attr('data-toggle', 'buttons-radio');
    if ( obj['severity'] == 'major' ) {
        sevBtns.append('<button type="button" id="major" class="btn disabled active btn-primary">Major</button>');
    } else {
        sevBtns.append('<button type="button" id="major" class="btn disabled">Major</button>');
    };
    if ( obj['severity'] == 'minor' ) {
        sevBtns.append('<button type="button" id="minor" class="btn disabled active btn-primary">Minor</button>');
    } else {
        sevBtns.append('<button type="button" id="minor" class="btn disabled">Minor</button>');
    };
    if ( obj['severity'] == 'atomic' ) {
        sevBtns.append('<button type="button" id="atomic" class="btn disabled active btn-primary">Atomic</button>');
    } else {
        sevBtns.append('<button type="button" id="atomic" class="btn disabled">Atomic</button>');
    };
    dl.append('<dt>Severity</dt><dd id="severity">'+sevBtns[0].outerHTML+'</dd>');
    
    dl.append('<dt>Author</dt><dd id="author">'+obj['author']+'</dd>');
    dl.append('<dt>Message</dt><dd id="message">'+obj['message']+'</dd>');
    modalBody.append(dl);
    modal.append(modalBody);
    modalFooter = $('<div>');
    modalFooter.addClass('modal-footer');
    modalFooter.append('<a href="#" id="modal-close" class="btn" data-dismiss="modal">Close</a>');
    modalFooter.append('<a href="#" onclick="save_event(\''+obj['id']+'-modal\')" id="modal-save" class="btn btn-primary hide">Save</a></div>');
    modal.append(modalFooter);
    modal.on('hidden', function () {
        $('#'+obj['id']+'-modal').replaceWith(event_modal(obj));
    });
    modal.on('hide', function () {
        modalVisible = false;
    });
    modal.on('show', function () {
        modalVisible = true
    });
    return modal
};

function editable_event_modal(div) {
    console.log('Making modal editable: ' + div);
    author = $( "#" + div + " #author" ).text();
    severity = $( "#" + div + " #severity .active" ).attr('id');
    message = $( "#" + div + " #message" ).text();
    $( "#" + div + " #modal-edit" ).hide();
    $( "#" + div + " #modal-close" ).text('Cancel');
    $( "#" + div + " #modal-save" ).show();
    $( "#" + div + " #author" ).html('<input type="text" id="author-input" value="'+author+'">');
    $( "#" + div + " #severity .btn" ).removeClass('disabled btn-primary');
    $( "#" + div + " #message" ).html('<textarea rows="3" type="text" id="message-input">'+message+'</textarea>');
}

function save_event(div) {
    div="#" + div
    author=username
    severity=$(div + ' #severity .active').attr('id');
    message=$(div + ' #message-input').val();
    id = $(div).attr('timestamp');
    console.debug('Saving event (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/timeline/"+id+"?message="+message+"&author="+author+"&severity="+severity,
        type: 'PUT',
        success: function(result) {
            id=id.toString().replace('.','')
            $( "#"+id+"-event .timeline_message" ).text(result['message']);
            $( "#"+id+"-event .timeline_author" ).text(result['author']);
            $( "#"+id+"-event" ).removeClass('major-timeline');
            $( "#"+id+"-event" ).removeClass('minor-timeline');
            $( "#"+id+"-event" ).removeClass('atomic-timeline');
            $( "#"+id+"-event" ).addClass(result['severity']+'-timeline');
            $(div).modal('hide');
            result['id'] = id;
            $(div).replaceWith(event_modal(result));
        }
    });
};

function save_new_event(div) {
    div="#new-event-modal"
    author=$(div + ' #author-input').val();
    severity=$(div + ' #severity .active').attr('id');
    message=$(div + ' #message-input').val();
    console.debug('Saving new event');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/timeline?message="+message+"&author="+author+"&severity="+severity,
        type: 'POST',
        success: function(result) {
            writeEvent(result, 0, 0);
            $(div).modal('hide');
        }
    });
};

function getTimeline(team, incident, loadingDiv) {
    console.debug('Getting timeline...');
    if ( loadingDiv == true ) {
        $("#loadingModal").modal('show');
    }
    $.getJSON("/api/team/"+team+"/"+incident+"/timeline",function(result){
        if ( result['events'] != knownEvents ) {
            $(".tlevent").remove();
            result['events'].forEach(writeEvent);
            $("#loadingModal").modal('hide');
        };
    });
}

function delete_event(id) {
    if ( confirm("Are you sure you want to delete this event?") == true ) {
        console.debug('Deleting event (' + id + ')');
        $.ajax({
            url: "/api/team/"+team+"/"+incident+"/timeline/"+id,
            type: 'DELETE',
            success: function(result) {
                id=id.toString().replace('.','')
                $( "#"+id+"-event" ).remove();
            }
        });
    };
};

function change_sev_event(id, sev) {
    console.debug('Changing sev level to '+ sev + ' for event (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/timeline/"+id+'?severity='+sev,
        type: 'PUT',
        success: function(result) {
            id=id.toString().replace('.','')
            $( "#"+id+"-event" ).removeClass('major-timeline');
            $( "#"+id+"-event" ).removeClass('minor-timeline');
            $( "#"+id+"-event" ).removeClass('atomic-timeline');
            $( "#"+id+"-event" ).addClass(result['severity']+'-timeline');
            result['id'] = id;
            $("#"+id+"-modal").replaceWith(event_modal(result));
        }
    });
};

function writeTask(myTask, index, ar) {
    if ($("#tasklist.filter #" + myTask['severity']).hasClass('active') && $("#tasklist.filter #" + myTask['state']).hasClass('active')) {
        console.debug("Writing task: " + myTask['description']);
        o = $('<div>');
        o.addClass(myTask['severity']+'-tasklist task roundCorners '+myTask['state']);
        o.attr( 'id', myTask['id']+"-task");
        timestamp = $('<div>');
        timestamp.addClass('superscript');
        timestamp.attr( 'title', new Date(myTask['timestamp'] * 1000) );
        timestamp.text(getRelTime(myTask['timestamp'] * 1000));
        o.append(timestamp)
        owner = $('<div>');
        owner.addClass('owner');
        owner.text(myTask['owner']);
        o.append(owner);
        sym = $('<div>');
        sym.attr('id', myTask['id']+'-sym');
        sym.addClass('sym');
        sym.html('<img src="/img/sym_'+myTask['severity']+'.png">')
        o.append(sym);
       
        gear = $('<div id="'+myTask['id']+'" class="btn-group gear dropdown">' +
        '<a class="btn-mini dropdown-toggle" data-toggle="dropdown" role="button" href="#">' +
        '<i class="icon-cog"></i><span class="caret"></span></a>' + 
        '<ul class="dropdown-menu pull-right" role="menu">' +
        '<li><a data-toggle="modal" data-target="#'+myTask['id']+'-modal">View</a></li>' +
        '<li class="divider"></li>' +
        '<li><a href="#" onclick="assign_task('+myTask['id']+', \''+username+'\')">Assign to Me</a></li>' +
        '<li class="taskDone" ><a href="#" onclick="task_done('+myTask['id']+')">Task Done!</a></li>' +
        '<li>Set Severity Level</li>' + 
        '<li><a href="#" onclick="change_sev_task('+myTask['id']+', \'major\')">Major</a></li>' +
        '<li><a href="#" onclick="change_sev_task('+myTask['id']+', \'minor\')">Minor</a></li>' +
        '<li><a href="#" onclick="change_sev_task('+myTask['id']+', \'atomic\')">Atomic</a></li>' +
        '<li>Delete Event</li>' +
        '<li><a href="#" onclick="delete_task('+myTask['id']+')">Delete</a></li>' +
        '</ul>');

        o.append(gear);
        o.append(task_modal(myTask));

        descrip = $('<div>');
        descrip.addClass('description');
        if ( myTask['description'].length > 140 ) { 
            descrip.text(myTask['description'].substring(0,140) + "...");
        } else {
            descrip.text(myTask['description']);
        }
        o.append(descrip);
        $("#tasklistItem").prepend(o);
        
        $( ".closed .taskDone").remove();
        $( ".open" ).addClass('alert-success');
        $( ".closed" ).addClass('alert-danger');
    };
}

function getTasklist(team, incident, loadingDiv) {
    console.debug('Getting tasklist...');
    if ( loadingDiv == true ) { 
        $("#loadingModal").modal('show');
    };
    $.getJSON("/api/team/"+team+"/"+incident+"/tasklist",function(result){
        console.debug(result);
        if ( result['tasks'] != knownTasks ) { 
            $(".task").remove();
            result['tasks'].forEach(writeTask);
            $( "#tasklistItem .menu" ).hide();
            $('#tasklistItem').mouseleave( function () {
                $( "#tasklistItem .menu" ).hide();
            });
            $("#loadingModal").modal('hide');
        };
    }); 
}

function new_task_modal() {
    console.log('building new task modal');
    modal = $('<div>');
    modal.addClass('modal hide fade');
    modal.attr('id', 'new-task-modal');
    modal.attr('tabindex', '-1');
    modal.attr('role', 'dialog');
    modal.attr('aria-labelledby', 'New Task Item');
    modal.attr('aria-hidden', 'true');
    modalHeader = $('<div>');
    modalHeader.addClass('modal-header');
    modalHeader.append('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>');
    modalHeader.append('<h3>New Task Item</h3>');
    modal.append(modalHeader);
    modalBody = $('<div>');
    modalBody.addClass('modal-body');
    dl = $('<dl>');
    dl.addClass('dl-horizontal');
    dl.append('<dt>Owner</dt><dd id="author"><input type="text" id="owner-input" value="None"></dd>');
    sevBtns = $('<div>');
    sevBtns.addClass('btn-group');
    sevBtns.attr('data-toggle', 'buttons-radio');
    sevBtns.append('<button type="button" id="major" class="btn">Major</button>');
    sevBtns.append('<button type="button" id="minor" class="btn">Minor</button>');
    sevBtns.append('<button type="button" id="atomic" class="btn active">Atomic</button>');
    dl.append('<dt>Severity</dt><dd id="severity">'+sevBtns[0].outerHTML+'</dd>');
    dl.append('<dt>Description</dt><dd id="description"><textarea rows="3" type="text" id="description-input"></textarea></dd>');
    modalBody.append(dl);
    modal.append(modalBody);
    modalFooter = $('<div>');
    modalFooter.addClass('modal-footer');
    modalFooter.append('<a href="#" id="modal-close" class="btn" data-dismiss="modal">Cancel</a>');
    modalFooter.append('<a href="#" onclick="save_new_task()" id="modal-save" class="btn btn-primary">Save</a></div>');
    modal.append(modalFooter);
    $('#new-task-modal').replaceWith(modal);
    $('#new-task-modal').modal();
}

function task_modal(obj) {
    modal = $('<div>');
    modal.addClass('modal hide fade');
    modal.attr('id', obj['id']+'-modal');
    modal.attr('tabindex', '-1');
    modal.attr('role', 'dialog');
    modal.attr('aria-labelledby', 'myModalLabel');
    modal.attr('aria-hidden', 'true');
    modal.attr('uid', obj['id']);
    modalHeader = $('<div>');
    modalHeader.addClass('modal-header');
    modalHeader.append('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>');
    modalHeader.append('<h3>Detailed View</h3>');
    modalHeader.append('<a href="#" onclick="editable_task_modal(\''+obj['id']+'-modal\')" id="modal-edit" class="btn btn-primary" >Edit</a></div>');
    modal.append(modalHeader);
    modalBody = $('<div>');
    modalBody.addClass('modal-body');
    dl = $('<dl>');
    dl.addClass('dl-horizontal');
    dl.append('<dt>Timestamp</dt><dd id="timestamp">'+new Date(obj['timestamp'] * 1000)+'</dd><dt>');
    sevBtns = $('<div>');
    sevBtns.addClass('btn-group');
    sevBtns.attr('data-toggle', 'buttons-radio');
    if ( obj['severity'] == 'major' ) {
        sevBtns.append('<button type="button" id="major" class="btn disabled active btn-primary">Major</button>');
    } else {
        sevBtns.append('<button type="button" id="major" class="btn disabled">Major</button>');
    };
    if ( obj['severity'] == 'minor' ) {
        sevBtns.append('<button type="button" id="minor" class="btn disabled active btn-primary">Minor</button>');
    } else {
        sevBtns.append('<button type="button" id="minor" class="btn disabled">Minor</button>');
    };
    if ( obj['severity'] == 'atomic' ) {
        sevBtns.append('<button type="button" id="atomic" class="btn disabled active btn-primary">Atomic</button>');
    } else {
        sevBtns.append('<button type="button" id="atomic" class="btn disabled">Atomic</button>');
    };
    dl.append('<dt>Severity</dt><dd id="severity">'+sevBtns[0].outerHTML+'</dd>');

    dl.append('<dt>Author</dt><dd id="author">'+obj['author']+'</dd>');
    dl.append('<dt>Owner</dt><dd id="owner">'+obj['owner']+'</dd>');
    dl.append('<dt>Description</dt><dd id="description">'+obj['description']+'</dd>');
    modalBody.append(dl);
    modalBody.append(dl);
    modal.append(modalBody);
    modalFooter = $('<div>');
    modalFooter.addClass('modal-footer');
    modalFooter.append('<a href="#" id="modal-close" class="btn" data-dismiss="modal">Close</a>');
    modalFooter.append('<a href="#" onclick="save_task(\''+obj['id']+'-modal\')" id="modal-save" class="btn btn-primary hide">Save</a></div>');
    modal.append(modalFooter);
    modal.on('hidden', function () {
        $('#'+obj['id']+'-modal').replaceWith(task_modal(obj));
    });
    modal.on('hide', function () {
        modalVisible = false;
    });
    modal.on('show', function () {
        modalVisible = true
    });
    return modal
};

function editable_task_modal(div) {
    console.log('Making modal editable: ' + div);
    author = $( "#" + div + " #author" ).text();
    owner = $( "#" + div + " #owner" ).text();
    severity = $( "#" + div + " #severity .active" ).attr('id');
    description = $( "#" + div + " #description" ).text();
    $( "#" + div + " #modal-edit" ).hide();
    $( "#" + div + " #modal-close" ).text('Cancel');
    $( "#" + div + " #modal-save" ).show();
    $( "#" + div + " #author" ).html('<input type="text" id="author-input" value="'+author+'">');
    $( "#" + div + " #owner" ).html('<input type="text" id="owner-input" value="'+owner+'">');
    $( "#" + div + " #severity .btn" ).removeClass('disabled btn-primary');
    $( "#" + div + " #description" ).html('<textarea rows="3" type="text" id="description-input">'+description+'</textarea>');
}

function save_task(div) {
    div="#" + div
    author=$(div + ' #author-input').val();
    owner=$(div + ' #owner-input').val();
    severity=$(div + ' #severity .active').attr('id');
    description=$(div + ' #description-input').val();
    id = $(div).attr('uid');
    console.debug('Saving task (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/tasklist/"+id+"?description="+description+"&author="+author+"&severity="+severity+"&owner="+owner,
        type: 'PUT',
        success: function(result) {
            $( "#"+id+"-sym" ).html('<img src="/img/sym_'+result['severity']+'.png">');
            $( "#"+id+"-task" ).removeClass('major-tasklist');
            $( "#"+id+"-task" ).removeClass('minor-tasklist');
            $( "#"+id+"-task" ).removeClass('atomic-tasklist');
            $( "#"+id+"-task" ).addClass(result['severity']+'-tasklist');

            $( "#"+id+"-task .description" ).text(result['description']);
            $( "#"+id+"-task .owner" ).text(result['owner']);

            $(div).modal('hide');
            $(div).replaceWith(task_modal(result));
        }
    });
};

function save_new_task(div) {
    div="#new-task-modal"
    owner=$(div + ' #owner-input').val();
    severity=$(div + ' #severity .active').attr('id');
    description=$(div + ' #description-input').val();
    console.debug('Saving new task');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/tasklist?description="+description+"&author="+username+"&severity="+severity+"&owner="+owner,
        type: 'POST',
        success: function(result) {
            writeTask(result, 0, 0);
            $(div).modal('hide');
        }
    });
};

function delete_task(id) {
    if ( confirm("Are you sure you want to delete this task?") == true ) {
        console.debug('Deleting task (' + id + ')');
        $.ajax({
            url: "/api/team/"+team+"/"+incident+"/tasklist/"+id,
            type: 'DELETE',
            success: function(result) {
                $( "#"+id+"-task" ).remove();
            }
        });
    };
};

function assign_task(id, user) {
    console.debug('Assigning task (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/tasklist/"+id+"?owner="+user,
        type: 'PUT',
        success: function(result) {
            $( "#"+id+"-task .owner" ).text(result['owner']);
        }
    });
};

function task_done(id) {
    console.debug('Closing task (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/tasklist/"+id+"?state=closed",
        type: 'PUT',
        success: function(result) {
            $( "#"+id+"-task" ).removeClass('alert-success');
            $( "#"+id+"-task" ).addClass('alert-danger');
        }   
    }); 
};

function change_sev_task(id, sev) {
    console.debug('Changing sev level to '+ sev + ' for task (' + id + ')');
    $.ajax({
        url: "/api/team/"+team+"/"+incident+"/tasklist/"+id+'?severity='+sev,
        type: 'PUT',
        success: function(result) {
            $( "#"+id+"-sym" ).html('<img src="/img/sym_'+result['severity']+'.png">');
            $( "#"+id+"-task" ).removeClass('major-tasklist');
            $( "#"+id+"-task" ).removeClass('minor-tasklist');
            $( "#"+id+"-task" ).removeClass('atomic-tasklist');
            $( "#"+id+"-task" ).addClass(result['severity']+'-tasklist');
        }
    });
};
