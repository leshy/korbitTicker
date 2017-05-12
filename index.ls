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

  # env.logger.outputs.push new logger3.Influx do
  #   connection: { database: 'korbitz', host: 'rlog' }
  #   tagFields: { +module, +app }

  tick = -> 
    p.props do
      korbit: request.get('https://api.korbit.co.kr/v1/ticker').then -> Number JSON.parse(it).last
      bitstamp: request.get('https://www.bitstamp.net/api/v2/ticker/btceur/').then -> Number JSON.parse(it).last
      exchange: request.get('https://api.fixer.io/latest').then -> Number JSON.parse(it).rates.KRW

    .then ({korbit, bitstamp, exchange}) ->
      data = time: new Date().getTime(), diff: (1 - (bitstamp / (korbit / exchange))) * 100, exchange: exchange, korbit: korbit, bitstamp: bitstamp
      env.logger.log "diff is #{round(data.diff,2)}%, korbit: #{data.korbit} KRW, bitstamp: #{data.bitstamp} EUR, exchange rate: #{data.exchange}", data

  setInterval tick, 60000
  tick()
