var Backbone = require('backbone');
var AnalysisFactory = require('../../../src/analysis/analysis-factory');

describe('src/analysis/analysis-factory.js', function () {
  beforeEach(function () {
    this.fakeCamshaftReference = {
      getSourceNamesForAnalysisType: function (analysisType) {
        var map = {
          'trade-area': ['source'],
          'estimated-population': ['source']
        };
        return map[analysisType];
      },
      getParamNamesForAnalysisType: function (analysisType) {
        var map = {
          'trade-area': ['kind', 'time'],
          'estimated-population': ['columnName']
        };
        return map[analysisType];
      }
    };
    this.analysisCollection = new Backbone.Collection();
    this.analysisFactory = new AnalysisFactory({
      camshaftReference: this.fakeCamshaftReference,
      analysisCollection: this.analysisCollection,
      map: jasmine.createSpyObj('map', ['reload'])
    });
  });

  describe('.analyse', function () {
    it('should generate and return a new analysis', function () {
      var subwayStops = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        query: 'SELECT * FROM subway_stops'
      });

      expect(subwayStops.attributes).toEqual({
        id: 'a0',
        type: 'source',
        query: 'SELECT * FROM subway_stops'
      });
    });

    it('should set attrs on the analysis models', function () {
      this.analysisFactory = new AnalysisFactory({
        apiKey: 'THE_API_KEY',
        authToken: 'THE_AUTH_TOKEN',
        camshaftReference: this.fakeCamshaftReference,
        analysisCollection: this.analysisCollection,
        map: jasmine.createSpyObj('map', ['reload'])
      });

      var analysisModel = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        query: 'SELECT * FROM subway_stops'
      });

      expect(analysisModel.get('apiKey')).toEqual('THE_API_KEY');
      expect(analysisModel.get('authToken')).toEqual('THE_AUTH_TOKEN');
    });

    it('should add new analysis to the collection of analysis', function () {
      var subwayStops = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        query: 'SELECT * FROM subway_stops'
      });

      expect(this.analysisCollection.at(0)).toEqual(subwayStops);
    });

    it('should not create a new analysis if an analysis with the same id was created already', function () {
      var subwayStops1 = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        params: {
          query: 'SELECT * FROM subway_stops'
        }
      });

      var subwayStops2 = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        params: {
          query: 'SELECT * FROM subway_stops '
        }
      });

      expect(subwayStops1.cid).toEqual(subwayStops2.cid);
    });

    it('should recursively build the anlysis graph', function () {
      var estimatedPopulation = this.analysisFactory.analyse(
        {
          id: 'a2',
          type: 'estimated-population',
          params: {
            columnName: 'estimated_people',
            source: {
              id: 'a1',
              type: 'trade-area',
              params: {
                kind: 'walk',
                time: 300,
                source: {
                  id: 'a0',
                  type: 'source',
                  params: {
                    query: 'SELECT * FROM subway_stops'
                  }
                }
              }
            }
          }
        }
      );
      var tradeArea = estimatedPopulation.get('source');
      var subwayStops = tradeArea.get('source');
      expect(tradeArea.get('id')).toEqual('a1');
      expect(subwayStops.get('id')).toEqual('a0');
    });

    it('analysis should be re-created after it has been removed', function () {
      var subwayStops1 = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        params: {
          query: 'SELECT * FROM subway_stops'
        }
      });

      subwayStops1.remove();

      var subwayStops2 = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        params: {
          query: 'SELECT * FROM subway_stops '
        }
      });

      expect(subwayStops1.cid).not.toEqual(subwayStops2.cid);
    });

    it('should remove the analysis from the collection when analysis is removed', function () {
      var subwayStops1 = this.analysisFactory.analyse({
        id: 'a0',
        type: 'source',
        params: {
          query: 'SELECT * FROM subway_stops'
        }
      });

      expect(this.analysisCollection.size()).toEqual(1);

      subwayStops1.remove();

      expect(this.analysisCollection.size()).toEqual(0);
    });
  });

  describe('.findNodeById', function () {
    it('should traverse the analysis and return an existing node', function () {
      this.analysisFactory.analyse(
        {
          id: 'a2',
          type: 'estimated-population',
          params: {
            columnName: 'estimated_people',
            source: {
              id: 'a1',
              type: 'trade-area',
              params: {
                kind: 'walk',
                time: 300,
                source: {
                  id: 'a0',
                  type: 'source',
                  params: {
                    query: 'SELECT * FROM subway_stops'
                  }
                }
              }
            }
          }
        }
      );

      expect(this.analysisFactory.findNodeById('a2').get('id')).toEqual('a2');
      expect(this.analysisFactory.findNodeById('a1').get('id')).toEqual('a1');
      expect(this.analysisFactory.findNodeById('a0').get('id')).toEqual('a0');
    });

    it('should return undefined if node is not found', function () {
      expect(this.analysisFactory.findNodeById('something')).toBeUndefined();

      this.analysisFactory.analyse(
        {
          id: 'a2',
          type: 'estimated-population',
          params: {
            columnName: 'estimated_people',
            source: {
              id: 'a1',
              type: 'trade-area',
              params: {
                kind: 'walk',
                time: 300,
                source: {
                  id: 'a0',
                  type: 'source',
                  params: {
                    query: 'SELECT * FROM subway_stops'
                  }
                }
              }
            }
          }
        }
      );

      expect(this.analysisFactory.findNodeById('something')).toBeUndefined();
    });
  });
});
