require 'parse-ruby-client'
Parse.init :application_id => "e6Sd3RCndeGV6p2T7nxqDIo5rOfV4F13F8ruS4lU",
           :api_key        => "KNgVPhsP2CsfRINBZAEUlshOPnvtYozEdW9rOMD4"
# Parse is used to sync book data between mobile and web platforms


class UsersController < ApplicationController
  before_filter :authenticate_user!

  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    @users = User.all
  end

  #the page that displays social requests
  def usersPool
    @requests = Parse::Query.new("Requests").eq("responder", current_user.id).get
    @friends = Parse::Query.new("Friends").eq("user_id", current_user.id).get
    @users = User.all
    @user = User.find(current_user.id)
  end

  #show the user's profile including their books, friends and comments from others
  def show
    @users = User.all

    #includes 3 queries to Parse for relevant info
    query = Parse::Query.new("Books")
    @books = query.get
    @user = User.find(params[:id].delete('/').to_i)
    query.eq("user_id", @user.id)
    @myBooks = query.get
    friendsQuery = Parse::Query.new("Friends").eq("user_id", @user.id)
    @friends = friendsQuery.get
    commentsQuery = Parse::Query.new("Comments").eq("user_id", @user.id)
    @comments = commentsQuery.get

    #search & display books without leaving the page
    @results = Array.new
    @results = @books.select { |s| s["title"].include? params[:searchToken] } if !params[:searchToken].nil?
  end

  # simple method to update user info
  def update
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user], :as => :admin)
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  # retrieves parameters from form, stores everything in the book table (Parse)
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

  # deletes a book (warning displayed on :hover delete button)
  def deleteBook
    query = Parse::Query.new("Books")
    query.eq("user_id", current_user.id)
    @myBooks = query.get
    @myBooks[params[:indexToDelete].to_i].parse_delete
    redirect_to user_path(current_user), :notice => "deleted"
  end

  # when the user likes a book, up the like index by 1
  # TODO: restrict votes per IP/user.
  def likeBook
    like = Parse::Object.new("Likes")
    like["book_id"] = params[:book_id]
    like["by_user"] = current_user.id
    like.save
    redirect_to user_path(params[:user_id].to_i), :notice => "you liked the book."
  end

  #send a request to a user (unresponded reqs stored in table)
  def addFriend
    request = Parse::Object.new("Requests")
    request["initiator"] = params[:initiator].to_i
    request["responder"] = params[:responder].to_i
    request.save
    redirect_to user_path(params[:responder]), :notice =>"Request Sent"
  end

  # delete a friend (essentially destroys the 1-1 relationship thru js)
  def deFriend
    query = Parse::Query.new("Friends").eq("user_id",current_user.id)
    @friendsA = query.get
    queryB = Parse::Query.new("Friends").eq("user_id", params[:responder].to_i)
    @friendsB = queryB.get
  end

  # add a friend (add a FK to each other)
  # not the best solution due to the lack of API support for rails
  def acceptReq
    friend = Parse::Object.new("Friends")
    friend["user_id"] = current_user.id
    friend["friend_id"] = params[:initiator].to_i
    friend.save
    friendB = Parse::Object.new("Friends")
    friendB["friend_id"] = current_user.id
    friendB["user_id"] = params[:initiator].to_i
    friendB.save

    #after adding the friend, delete the request
    @requests = Parse::Query.new("Requests").eq("initiator", params[:initiator].to_i).get
    @requests.each do |r|
      if r["responder"] == current_user.id
        r.parse_delete
      end
    end
    redirect_to "/usersPool", :notice =>"You guys are now friends :)"
  end

  #properly handles declined friend requests
  def declineReq
    @requests = Parse::Query.new("Requests").eq("initiator", params[:initiator].to_i).get
    @requests.each do |r|
      if r["responder"] == current_user.id
        r.parse_delete
      end
    end
    redirect_to "/usersPool", :notice =>"Okay, you turned them down but we won't tell"
  end

  # adds a comment to the comment table (Parse)
  def addComment
    friend = Parse::Object.new("Comments")
    friend["commenter_id"] = current_user.id
    friend["user_id"] = params[:user_id].to_i
    friend["comment"] = params[:comment]
    friend.save
    redirect_to user_path(params[:user_id]), :notice =>"Comment added, please be nice and kind to each other ;)"
  end

  # deletes a user (only admin allowed)
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
