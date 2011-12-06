
get '/test/response_codes/continue' do
	respond(100, '100 - continue');
end

get '/test/response_codes/switchingprotocols' do
	respond(101, '101 - switchingprotocols');
end



get '/test/response_codes/ok' do
	respond(200, '200 - ok');
end

get '/test/response_codes/created' do
	respond(201, '201 - created');
end

get '/test/response_codes/accepted' do
	respond(202, '202 - accepted');
end

get '/test/response_codes/nonauthoritative' do
	respond(203, '203 - nonauthoritative');
end

get '/test/response_codes/nocontent' do
	respond(204, '204 - nocontent');
end

get '/test/response_codes/resetcontent' do
	respond(205, '205 - resetcontent');
end

get '/test/response_codes/partialcontent' do
	respond(206, '206 - partialcontent');
end


get '/test/response_codes/multiplechoices' do
	respond(300, '300 - multiplechoices');
end

get '/test/response_codes/movedpermanently' do
	respond(301, '301 - movedpermanently');
end

get '/test/response_codes/found' do
	respond(302, '302 - found');
end

get '/test/response_codes/seeother' do
	respond(303, '303 - seeother');
end

get '/test/response_codes/notmodified' do
	respond(304, '304 - notmodified');
end

get '/test/response_codes/useproxy' do
	respond(305, '305 - useproxy');
end

get '/test/response_codes/switchproxy' do
	respond(306, '306 - switchproxy');
end

get '/test/response_codes/temporaryredirect' do
	respond(307, '307 - temporaryredirect');
end

get '/test/response_codes/resumeincomplete' do
	respond(308, '308 - resumeincomplete');
end


get '/test/response_codes/badrequest' do
	respond(400, '400 - badrequest');
end

get '/test/response_codes/unauthorized' do
	respond(401, '401 - unauthorized');
end

get '/test/response_codes/paymentrequired' do
	respond(402, '402 - paymentrequired');
end

get '/test/response_codes/forbidden' do
	respond(403, '403 - forbidden');
end

get '/test/response_codes/notfound' do
	respond(404, '404 - notfound');
end

get '/test/response_codes/methodnotallowed' do
	respond(405, '405 - methodnotallowed');
end

get '/test/response_codes/notacceptable' do
	respond(406, '406 - notacceptable');
end

get '/test/response_codes/proxyauthenticationrequired' do
	respond(407, '407 - proxyauthenticationrequired');
end

get '/test/response_codes/requesttimeout' do
	respond(408, '408 - requesttimeout');
end

get '/test/response_codes/conflict' do
	respond(409, '409 - conflict');
end

get '/test/response_codes/gone' do
	respond(410, '410 - gone');
end

get '/test/response_codes/lengthrequired' do
	respond(411, '411 - lengthrequired');
end

get '/test/response_codes/preconditionfailed' do
	respond(412, '412 - preconditionfailed');
end

get '/test/response_codes/requestentitytoolarge' do
	respond(413, '413 - requestentitytoolarge');
end

get '/test/response_codes/requesturitoolong' do
	respond(414, '414 - requesturitoolong');
end

get '/test/response_codes/unsupportedmediatype' do
	respond(415, '415 - unsupportedmediatype');
end

get '/test/response_codes/requestrangenotsatisfied' do
	respond(416, '416 - requestrangenotsatisfied');
end

get '/test/response_codes/expectationfailed' do
	respond(417, '417 - expectationfailed');
end

get '/test/response_codes/unprocessableentity' do
	respond(422, '422 - unprocessableentity');
end


get '/test/response_codes/internalservererror' do
	respond(500, '501 - internalservererror');
end

get '/test/response_codes/notimplemented' do
	respond(501, '501 - notimplemented');
end

get '/test/response_codes/badgateway' do
	respond(502, '502 - badgateway');
end

get '/test/response_codes/serviceunavailable' do
	respond(503, '503 - serviceunavailable');
end

get '/test/response_codes/gatewaytimeout' do
	respond(504, '504 - gatewaytimeout');
end

get '/test/response_codes/httpversionnotsupported' do
	respond(505, '505 - httpversionnotsupported');
end



get '/test/response_codes/informational' do
	respond(199, '199 - informational');
end

get '/test/response_codes/successful' do
	respond(299, '299 - successful');
end

get '/test/response_codes/redirect' do
	respond(399, '399 - redirect');
end

get '/test/response_codes/clienterrror' do
	respond(499, '499 - clienterrror');
end

get '/test/response_codes/servererror' do
	respond(599, '599 - servererror');
end



