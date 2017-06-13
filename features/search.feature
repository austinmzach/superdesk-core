Feature: Search Feature

    @auth
    Scenario: Can search ingest
        Given "ingest"
            """
            [{"guid": "1"}]
            """
        When we get "/search"
        Then we get list with 1 items

    @auth
    Scenario: Can search archive
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
            """
            [{"guid": "1", "task": {"desk": "#desks._id#"}, "state": "in_progress"}]
            """
        When we get "/search"
        Then we get list with 1 items

    @auth
    Scenario: Can not search private content
        Given "archive"
            """
            [{"guid": "1"}]
            """
        When we get "/search"
        Then we get list with 0 items

    @auth
    Scenario: Can limit search to 1 result per shard
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
        """
        [{"guid": "1", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "2", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "3", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "4", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "5", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "6", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "7", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "8", "task": {"desk": "#desks._id#"}, "state": "in_progress"},
         {"guid": "9", "task": {"desk": "#desks._id#"}, "state": "in_progress"}]
        """
        Then we set elastic limit
        When we get "/search"
        Then we get list with <6 items

    @auth
    Scenario: Search Invisible stages without desk membership
        Given empty "desks"
        When we post to "users"
            """
            {"username": "foo", "email": "foo@bar.com", "is_active": true, "sign_off": "abc"}
            """
        When we post to "/desks"
            """
            {"name": "Sports Desk", "members": [{"user": "#users._id#"}]}
            """
        And we get "/desks"
        Then we get list with 1 items
            """
            {"_items": [{"name": "Sports Desk", "members": [{"user": "#users._id#"}]}]}
            """
        When we get the default incoming stage
        When we post to "/archive"
            """
            [{"guid": "item1", "state": "in_progress", "task": {"desk": "#desks._id#",
            "stage": "#desks.incoming_stage#", "user": "#users._id#"}}]
            """
        Then we get response code 201
        When we get "/search"
        Then we get list with 1 items
        When we patch "/stages/#desks.incoming_stage#"
            """
            {"is_visible": false}
            """
        Then we get response code 200
        When we get "/search"
        Then we get list with 0 items
        When we get "/archive/#archive._id#"
        Then we get response code 403

    @auth
    Scenario: Search returns archived items in Invisible stages without desk membership
        Given "users"
        """
        [{"username": "foo", "email": "foo@bar.com", "is_active": true, "sign_off": "abc"}]
        """
        And "desks"
        """
        [{"name": "Sports Desk", "members": [{"user": "#users._id#"}]}]
        """
        And "archived"
            """
            [{"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
              "genre": [{"name": "Broadcast Script", "qcode": "Broadcast Script"}], "headline": "headline",
              "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
              "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#users._id#"},
              "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
            """
        When we post to "/archive"
            """
            [{"guid": "item1", "state": "in_progress", "task": {"desk": "#desks._id#",
            "stage": "#desks.incoming_stage#", "user": "#users._id#"}}]
            """
        Then we get response code 201
        When we get "/search"
        Then we get list with 2 items
        When we patch "/stages/#desks.incoming_stage#"
            """
            {"is_visible": false}
            """
        Then we get response code 200
        When we get "/search"
        Then we get list with 1 items
        When we get "/archive/#archive._id#"
        Then we get response code 403


    @auth @test
    Scenario: Search Invisible stages with desk membership
        Given empty "desks"
        And the "validators"
          """
            [
            {
                "schema": {},
                "type": "text",
                "act": "publish",
                "_id": "publish_text"
            },
            {
                "_id": "publish_composite",
                "act": "publish",
                "type": "composite",
                "schema": {}
            }
            ]
          """
        When we post to "/desks"
            """
            {"name": "Sports Desk", "members": [{"user": "#CONTEXT_USER_ID#"}]}
            """
        And we get "/desks"
        Then we get list with 1 items
            """
            {"_items": [{"name": "Sports Desk", "members": [{"user": "#CONTEXT_USER_ID#"}]}]}
            """
        When we get the default incoming stage
        When we post to "/archive"
            """
            [{"guid": "item1", "state": "in_progress", "task": {"desk": "#desks._id#",
            "stage": "#desks.incoming_stage#", "user": "#users._id#",
            "subject":[{"qcode": "17004000", "name": "Statistics"}],
            "slugline": "test",
            "body_html": "Test Document body"}}]
            """
        Then we get response code 201
        When we get "/search"
        Then we get list with 1 items
        When we patch "/stages/#desks.incoming_stage#"
            """
            {"is_visible": false}
            """
        Then we get response code 200
        When we get "/search"
        Then we get list with 1 items
        When we get "/archive/#archive._id#"
        Then we get response code 200
        When we login as user "foo" with password "bar" and user type "user"
        When we get "/search"
        Then we get list with 0 items
        When we get "/archive/#archive._id#"
        Then we get response code 403
        When we setup test user
        And we publish "#archive._id#" with "publish" type and "published" state
        Then we get OK response
        When we get "/published"
        Then we get list with 1 items
        When we get "/archive/#archive._id#"
        Then we get response code 200
        When we login as user "foo" with password "bar" and user type "user"
        When we get "/search"
        Then we get list with 0 items
        When we get "/published"
        Then we get list with 0 items
        When we get "/archive/#archive._id#"
        Then we get response code 403


    @auth
    Scenario: Search by slugline
        Given "ingest"
            """
            [{"guid": "1", "slugline": "ABUSE PHOTO"}]
            """
        When we get "/search?source={"query":{"filtered":{"filter": null,"query":{"query_string":{"query":"slugline:(abuse)","lenient":false,"default_operator":"AND"}}}}}"
        Then we get list with 1 items
        When we get "/search?source={"query":{"filtered":{"filter": null,"query":{"query_string":{"query":"slugline:(absent)","lenient":false,"default_operator":"AND"}}}}}"
        Then we get list with 0 items

    @auth
    Scenario: Get item by guid no matter where it is
        Given "ingest"
        """
        [{"_id": "item-ingest"}]
        """
        And "archive"
        """
        [{"_id": "item-archive"}]
        """
        And "published"
        """
        [{"_id": "item-published", "state": "published"}]
        """

        When we get "/search/item-ingest"
        Then we get response code 200

        When we get "/search/item-archive"
        Then we get response code 200

        When we get "/search/item-published"
        Then we get response code 200

    @auth
    Scenario: Search returns spiked content from archive
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
            """
            [{"guid": "1", "state": "spiked", "task": {"desk": "#desks._id#"}},
            {"guid": "2", "state": "in_progress", "task": {"desk": "#desks._id#"}}]
            """
        When we get "/search"
        Then we get list with 2 items

    @auth
    Scenario: Search returns only current users drafts
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
            """
            [{"guid": "1", "state": "draft", "task": {"desk": "#desks._id#", "user": "123"}},
            {"guid": "2", "state": "in_progress", "task": {"desk": "#desks._id#", "user": "#users.id#"}}]
            """
        When we get "/search"
        Then we get list with 1 items
            """
            {"_items": [{"guid": "2"}]}
            """

    @auth
    Scenario: Search returns only spiked content when filtered from archive
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
            """
            [{"guid": "1", "state": "spiked", "task": {"desk": "#desks._id#"}},
            {"guid": "2", "state": "draft", "task": {"desk": "#desks._id#"}}]
            """
        When we get "/search?source={"query":{"filtered":{"filter":{"and":[{"term":{"state":"spiked"}}]}}}}"
        Then we get list with 1 items

    @auth
    Scenario: Search items with highlight
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
        """
        [{"guid": "1", "state": "in_progress", "task": {"desk": "#desks._id#"},
         "headline": "Foo", "body_html": "foo"},
        {"guid": "2", "state": "in_progress", "task": {"desk": "#desks._id#"},
         "headline": "bar", "body_html": "bar"}]
        """
        When we get "/search?source={"query": {"filtered": {"query": {"query_string": {"query": "(foo)", "lenient": false, "default_operator": "AND"}}}}}"
        Then we get list with 1 items
        """
        {
            "_items": [{"guid": "1", "state": "in_progress", "task": {"desk": "#desks._id#"},
                        "headline": "Foo", "body_html": "foo", "es_highlight": "__no_value__"}]
        }
        """
        When we get "/search?es_highlight=1&source={"query": {"filtered": {"query": {"query_string": {"query": "(foo)", "lenient": false, "default_operator": "AND"}}}}}"
        Then we get list with 1 items
        """
        {
            "_items": [{"guid": "1", "state": "in_progress", "task": {"desk": "#desks._id#"},
                        "headline": "Foo", "body_html": "foo",
                        "es_highlight": {
                            "headline": ["<span class=\"es-highlight\">Foo</span>"],
                            "body_html": ["<span class=\"es-highlight\">foo</span>"]
                        }}]
        }
        """

    @auth
    Scenario: Search items with projections
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
        """
        [{"guid": "1", "state": "in_progress", "task": {"desk": "#desks._id#"},
         "headline": "Foo", "body_html": "foo"},
        {"guid": "2", "state": "in_progress", "task": {"desk": "#desks._id#"},
         "headline": "bar", "body_html": "bar"}]
        """
        When we get "/search?source={"query": {"filtered": {"query": {"query_string": {"query": "(foo)", "lenient": false, "default_operator": "AND"}}}}}"
        Then we get list with 1 items
        """
        {
            "_items": [{"guid": "1", "state": "in_progress", "task": {"desk": "#desks._id#"},
                        "headline": "Foo", "body_html": "foo", "es_highlight": "__no_value__"}]
        }
        """
        When we get "/search?projections=["headline"]&source={"query": {"filtered": {"query": {"query_string": {"query": "(foo)", "lenient": false, "default_operator": "AND"}}}}}"
        Then we get list with 1 items
        And we get "body_html" does not exist
        And we get "state" does not exist
        And we get "headline" does exist