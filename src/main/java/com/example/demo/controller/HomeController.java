package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;
import software.amazon.awssdk.services.dynamodb.model.ScanRequest;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
public class HomeController {
    
    @Autowired
    private DynamoDbClient dynamoDbClient;
    
    @GetMapping("/")
    public String home(Model model) {
        List<User> users = dynamoDbClient.scan(ScanRequest.builder()
        .tableName("Users")
        .build()).items().stream()
        .map(item -> new User(item.get("id").s(), item.get("name").s()))
        .collect(Collectors.toList());

        model.addAttribute("users", users);

        return "index";
    }

    @PostMapping("/register")
    public String register() {
        dynamoDbClient.putItem(PutItemRequest.builder()
        .tableName("Users")
        .item(Map.of(
            "id", AttributeValue.builder().s("1").build(),
            "name", AttributeValue.builder().s("John Doe").build()
        ))
        .build());
        return "index";
    }

    private static class User {
        private String id;
        private String name;

        public User(String id, String name) {
            this.id = id;
            this.name = name;
        }

        public String getId() {
            return id;
        }

        public String getName() {
            return name;
        }
    }


} 