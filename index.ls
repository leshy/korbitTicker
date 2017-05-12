require! {
  ribcage: { init }
  leshdash: { map, round }
  'request-promise': request
  bluebird: p
  'logger3/server': logger3
}


env = {} 

init env, (err,env) ->
  env.logger.addTags pid: process.pid, app: "korbitTicker"

  env.logger.outputs.push new logger3.Influx do
    connection: { database: 'korbit', host: 'rlog' }
    tagFields: { +module, +app, +metric }

  tick = -> 
    p.props do
      korbit: request.get('https://api.korbit.co.kr/v1/ticker').then -> Number JSON.parse(it).last
      bitstamp: request.get('https://www.bitstamp.net/api/v2/ticker/btceur/').then -> Number JSON.parse(it).last
      exchange: request.get('https://api.fixer.io/latest').then -> Number JSON.parse(it).rates.KRW

    .then ({korbit, bitstamp, exchange}) ->
      data = time: new Date().getTime(), diff: (1 - (bitstamp / (korbit / exchange))) * 100, exchange: exchange, korbitEUR: korbit / exchange, korbit: korbit, bitstamp: bitstamp
      
      env.logger.log "diff #{round(data.diff,2)}%" { diff: data.diff, metric: 'diff' }, metric: 'diff'
      env.logger.log "korbit #{data.korbit / data.exchange} EUR" { korbit: data.korbit, last: data.korbit / data.exchange, }, metric: 'korbit'
      env.logger.log "bitstamp #{data.bitstamp} EUR" { last: data.bitstamp }, metric: 'bitstamp'
      env.logger.log "exchange #{data.exchange}" { exchange: data.exchange }, metric: 'exchange'
      
  setInterval tick, 60000
  tick()





