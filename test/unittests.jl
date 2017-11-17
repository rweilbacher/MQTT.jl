using Base.Test
@testset "topic_wildcard_len_check" begin
    @test_throws MQTT_ERR_INVAL topic_wildcard_len_check("+")
    @test topic_wildcard_len_check("bar") == nothing
    @test_throws MQTT_ERR_INVAL topic_wildcard_len_check("#")
    @test_throws MQTT_ERR_INVAL topic_wildcard_len_check("")
end;

@testset "filter_wildcard_len_check" begin
    @test_throws MQTT_ERR_INVAL filter_wildcard_len_check("")
    @test_throws MQTT_ERR_INVAL filter_wildcard_len_check("#/")
    @test_throws MQTT_ERR_INVAL filter_wildcard_len_check("f+oo/bar/more")
    @test_throws MQTT_ERR_INVAL filter_wildcard_len_check("f#oo/bar/more")
    @test filter_wildcard_len_check("foo/bar/more") == nothing
    @test filter_wildcard_len_check("foo/bar/more/#") == nothing
    @test filter_wildcard_len_check("foo/+/bar/more") == nothing
end;
