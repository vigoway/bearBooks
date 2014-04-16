require 'parse-ruby-client'
Parse.init :application_id => "e6Sd3RCndeGV6p2T7nxqDIo5rOfV4F13F8ruS4lU",
           :api_key        => "KNgVPhsP2CsfRINBZAEUlshOPnvtYozEdW9rOMD4"

class UsersController < ApplicationController
  before_filter :authenticate_user!

  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    @users = User.all
  end

  def usersPool
    @requests = Parse::Query.new("Requests").eq("responder", current_user.id).get
    @friends = Parse::Query.new("Friends").eq("user_id", current_user.id).get
    @users = User.all
    @user = User.find(current_user.id)
  end

  def show
    @users = User.all
    query = Parse::Query.new("Books")
    @books = query.get
    @user = User.find(params[:id].delete('/').to_i)
    query.eq("user_id", @user.id)
    @myBooks = query.get
    friendsQuery = Parse::Query.new("Friends").eq("user_id", @user.id)
    @friends = friendsQuery.get
    commentsQuery = Parse::Query.new("Comments").eq("user_id", @user.id)
    @comments = commentsQuery.get
    @results = Array.new
    @results = @books.select { |s| s["title"].include? params[:searchToken] } if !params[:searchToken].nil?
  end
  
  def update
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user], :as => :admin)
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  def uploadBook
    new_book = Parse::Object.new("Books")
    new_book["title"] = params[:title]
    new_book["author"] = params[:author]
    new_book["price"] = params[:price]
    new_book["course"] = params[:course]
    new_book["ISBN"] = params[:ISBN]
    new_book["description"] = params[:description]
    new_book["user_id"] = current_user.id
    result = new_book.save
    redirect_to user_path(current_user), :notice => current_user.id
  end

  def deleteBook
    query = Parse::Query.new("Books")
    query.eq("user_id", current_user.id)
    @myBooks = query.get
    @myBooks[params[:indexToDelete].to_i].parse_delete
    redirect_to user_path(current_user), :notice => "deleted"
  end

  def likeBook
    like = Parse::Object.new("Likes")
    like["book_id"] = params[:book_id]
    like["by_user"] = current_user.id
    like.save
    redirect_to user_path(params[:user_id].to_i), :notice => "you liked the book."
  end

  def addFriend
    request = Parse::Object.new("Requests")
    request["initiator"] = params[:initiator].to_i
    request["responder"] = params[:responder].to_i
    request.save
    redirect_to user_path(params[:responder]), :notice =>"Request Sent"
  end

  def deFriend
    query = Parse::Query.new("Friends").eq("user_id",current_user.id)
    @friendsA = query.get
    queryB = Parse::Query.new("Friends").eq("user_id", params[:responder].to_i)
    @friendsB = queryB.get
  end

  def acceptReq
    friend = Parse::Object.new("Friends")
    friend["user_id"] = current_user.id
    friend["friend_id"] = params[:initiator].to_i
    friend.save
    friendB = Parse::Object.new("Friends")
    friendB["friend_id"] = current_user.id
    friendB["user_id"] = params[:initiator].to_i
    friendB.save
    @requests = Parse::Query.new("Requests").eq("initiator", params[:initiator].to_i).get
    @requests.each do |r|
      if r["responder"] == current_user.id
        r.parse_delete
      end
    end
    redirect_to "/usersPool", :notice =>"You guys are now friends :)"
  end

  def declineReq
    @requests = Parse::Query.new("Requests").eq("initiator", params[:initiator].to_i).get
    @requests.each do |r|
      if r["responder"] == current_user.id
        r.parse_delete
      end
    end
    redirect_to "/usersPool", :notice =>"Okay, you turned them down but we won't tell others :("
  end

  def addComment
    friend = Parse::Object.new("Comments")
    friend["commenter_id"] = current_user.id
    friend["user_id"] = params[:user_id].to_i
    friend["comment"] = params[:comment]
    friend.save
    redirect_to user_path(params[:user_id]), :notice =>"Comment added, please be nice and kind to each other ;)"
  end

  def destroy
    authorize! :destroy, @user, :message => 'Not authorized as an administrator.'
    user = User.find(params[:id])
    unless user == current_user
      user.destroy
      redirect_to users_path, :notice => "User deleted."
    else
      redirect_to users_path, :notice => "Can't delete yourself."
    end
  end
end