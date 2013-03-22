$(document).ready(function() {
    ko.applyBindings(new AppViewModel());
 });

function AppViewModel() {
    this.teamName = ko.observable('');

    this.submitTeam = function() {
        gotoURL = location.protocol + "//" + location.host + '/app/' + this.teamName();
        console.debug('Clicked submit...' + gotoURL);
        window.location = gotoURL;
    };

    this.createTeam = function() {
        gotoURL = location.protocol + "//" + location.host + '/app/' + this.teamName();
        $.post("./app/" + this.teamName(),{},function(data){
            window.location = gotoURL;
        }, "json");
    };
}

