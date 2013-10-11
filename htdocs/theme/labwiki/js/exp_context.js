var Exp = Backbone.Model.extend({});

var ExpList = Backbone.Collection.extend({
  model: Exp,
  parse: function (resp) {
    return resp.experiments;
  }
});

var exps = new ExpList();

var ExpView = Backbone.View.extend({
  tagName: 'option',

  render: function() {
    this.$el.html(this.model.toJSON().name);
    return this;
  },
});

var ExpListView = Backbone.View.extend({
  events: {},

  initialize: function() {
    this.listenTo(exps, 'add', this.addOne);
    this.listenTo(exps, 'reset', this.addAll);

    $('#save-exp').on('click', function() {
      new_exp = new Exp({ name: $('input#exp-name').val() });
      new_exp.url = 'http://localhost:8002/projects/' + $('select#project').val() +'/experiments';
      new_exp.save();
      exps.add(new_exp);
    });

    var select_project = $('select[name="propProject"]');
    var select_experiment = $('select[name="propExperiment"]');
    var select_slice = $('select[name="propSlice"]');

    select_project.change(function() {
      console.log(select_project.val());
      exps.reset();
      exps.url = 'http://localhost:8002/projects/' + select_project.val() + '/experiments';
      exps.fetch();

      var filtered_slices = _.find(geni_projects, function(proj) {
        return select_project.val() == proj.name;
      }).slices;

      select_slice.empty();
      _.each(filtered_slices, function(slice) {
        select_slice.append('<option value="' + slice.name +'">' + slice.name + '</option>');
      });
    }).change();
  },

  addOne: function( exp ) {
    var view = new ExpView({ model: exp });
    this.$el.append( view.render().el );
  },

  addAll: function() {
    this.$el.html('');
    exps.each(this.addOne, this);
  }
});
