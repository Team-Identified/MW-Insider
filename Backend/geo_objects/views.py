from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework import status
from rest_framework.reverse import reverse
from authorization.models import UserProfile
from authorization.tools import update_user_points
from config import GEO_OBJECTS_SEARCH_SIMILARITY, GEO_OBJECTS_SEARCH_MAX_RESULTS, NEARBY_OBJECTS_NOTIFY_RADIUS, \
    NEARBY_OBJECTS_EXPLORATION_RADIUS
from geo_objects.models import GeoObject, SubmittedGeoObject, UserObjectExploration
from geo_objects.serializers import GeoObjectSerializer, SubmittedGeoObjectSerializer, SearchRequestSerializer, \
    LocationRequestSerializer
from geo_objects.tools import get_nearby_objects
from rest_framework.permissions import IsAdminUser, AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework import viewsets
from fuzzywuzzy import fuzz


class GeoObjectViewSet(viewsets.ModelViewSet):
    """
    This viewset automatically provides `list`, `create`, `retrieve`,
    `update` and `destroy` actions.
    """
    queryset = GeoObject.objects.all()
    serializer_class = GeoObjectSerializer
    permission_classes = [IsAdminUser]


class GeoObjectRetrieveViewSet(viewsets.ViewSet):
    @staticmethod
    def retrieve(request, pk=None):
        queryset = GeoObject.objects.all()
        geo_object = get_object_or_404(queryset, pk=pk)
        serializer = GeoObjectSerializer(geo_object, context={'request': request})
        already_explored = False
        if request.user.is_authenticated:
            already_explored = \
                UserObjectExploration.objects.filter(user=request.user, geo_object=geo_object).count() > 0
        response_data = serializer.data
        response_data['explored'] = already_explored
        return Response(response_data)


class SubmittedGeoObjectViewSet(viewsets.ViewSet):
    queryset = SubmittedGeoObject.objects.all()
    serializer_class = SubmittedGeoObjectSerializer

    @staticmethod
    def retrieve(request, pk=None):
        queryset = SubmittedGeoObject.objects.all()
        geo_object = get_object_or_404(queryset, pk=pk)
        if geo_object.contributor == request.user or request.user.is_staff:
            serializer = SubmittedGeoObjectSerializer(geo_object, context={'request': request})
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            return Response({"detail": "forbidden"}, status=status.HTTP_403_FORBIDDEN)

    @staticmethod
    def list(request):
        if request.user.is_authenticated:
            if request.user.is_staff:
                queryset = SubmittedGeoObject.objects.all()
            else:
                queryset = SubmittedGeoObject.objects.filter(contributor=request.user.id)
            serializer = SubmittedGeoObjectSerializer(queryset, many=True, context={'request': request})
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            return Response({"detail": "Authentication credentials were not provided."},
                            status=status.HTTP_401_UNAUTHORIZED)

    @staticmethod
    def create(request):
        update_user_points(request.user, 15)

        serializer = SubmittedGeoObjectSerializer(data=request.data)
        if serializer.is_valid():
            contributor = None
            if request.user.is_authenticated:
                contributor = request.user
            serializer.save(contributor=contributor)
            return Response({"status": "ok"}, status=status.HTTP_200_OK)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def destroy(request, pk=None):
        queryset = SubmittedGeoObject.objects.all()
        geo_object = get_object_or_404(queryset, pk=pk)
        if geo_object.contributor == request.user or request.user.is_staff:
            geo_object.delete()
            return Response({"status": "ok"}, status=status.HTTP_200_OK)
        else:
            return Response({"detail": "forbidden"}, status=status.HTTP_403_FORBIDDEN)


class GetNearbyObjectsForUserView(APIView):
    """
    Get nearby objects for user by coordinates
    """

    permission_classes = [IsAuthenticated]
    serializer_class = LocationRequestSerializer

    @staticmethod
    def post(request):
        request_serializer = LocationRequestSerializer(data=request.data)
        if request_serializer.is_valid():
            latitude = request_serializer.data.get("latitude")
            longitude = request_serializer.data.get("longitude")
        else:
            return Response(request_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        objects = get_nearby_objects(request, (latitude, longitude))
        for geo_object in objects:
            if geo_object['distance'] < NEARBY_OBJECTS_EXPLORATION_RADIUS:
                geo_object_db = GeoObject.objects.get(id=geo_object['object']['id'])
                already_explored = UserObjectExploration.objects.filter(user=request.user,
                                                                        geo_object=geo_object_db).count() > 0
                if not already_explored:
                    object_exploration = UserObjectExploration(
                        user=request.user,
                        geo_object=geo_object_db,
                    )
                    object_exploration.save()

        data = {
            'input': {
                'latitude': latitude,
                'longitude': longitude
            },
            'count': len(objects),
            'objects': objects
        }
        return Response(data=data, status=status.HTTP_200_OK)


class NearbyObjectNotificationView(APIView):
    """
    Check if user need to be notified about any nearby object
    """

    permission_classes = [IsAuthenticated]
    serializer_class = LocationRequestSerializer

    @staticmethod
    def post(request):
        request_serializer = LocationRequestSerializer(data=request.data)
        if request_serializer.is_valid():
            latitude = request_serializer.data.get("latitude")
            longitude = request_serializer.data.get("longitude")
        else:
            return Response(request_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        objects = get_nearby_objects(request, (latitude, longitude), filter_radius=NEARBY_OBJECTS_NOTIFY_RADIUS)
        if len(objects) > 0:
            nearest_object = objects[0]["object"]
            distance = objects[0]["distance"]
            user = request.user
            user_profile = UserProfile.objects.get(user=user)
            geo_object = GeoObject.objects.get(id=nearest_object["id"])
            already_explored = UserObjectExploration.objects.filter(user=user, geo_object=geo_object).count() > 0

            if not already_explored:
                update_user_points(request.user, 20)
                object_exploration = UserObjectExploration(
                    user=user,
                    geo_object=geo_object,
                )
                object_exploration.save()

            user_tags = list(user_profile.notification_tags.names())
            object_tags = list(geo_object.tags.names())
            tag_similar = False
            for user_tag in user_tags:
                if tag_similar:
                    break
                for object_tag in object_tags:
                    if user_tag == object_tag:
                        tag_similar = True
                        break

            if tag_similar and not already_explored:
                data = {
                    'input': {
                        'latitude': latitude,
                        'longitude': longitude
                    },
                    'need_to_notify': True,
                    'object': nearest_object,
                    'distance': distance,
                }

                return Response(data=data, status=status.HTTP_200_OK)
        data = {
            'input': {
                'latitude': latitude,
                'longitude': longitude
            },
            'need_to_notify': False,
            'object': None,
            'distance': 0,
        }
        return Response(data=data, status=status.HTTP_200_OK)


class MyExplorationsView(APIView):
    permission_classes = [IsAuthenticated]

    @staticmethod
    def get(request):
        objects = UserObjectExploration.objects.filter(user=request.user).order_by('created')
        objects = objects.reverse()
        geo_objects = []
        for explored_object in objects:
            geo_objects.append(explored_object.geo_object)
        serializer = GeoObjectSerializer(geo_objects, context={'request': request}, many=True)
        data = serializer.data
        response_data = {'objects': data}
        return Response(data=response_data, status=status.HTTP_200_OK)


class GetLastExploredObject(APIView):
    permission_classes = [IsAuthenticated]

    @staticmethod
    def get(request):
        user = request.user
        last_explored_record = UserObjectExploration.objects.filter(user=user).order_by('created').last()
        if last_explored_record:
            last_object = last_explored_record.geo_object
            serializer = GeoObjectSerializer(last_object, context={'request': request})
            return Response(data={
                "exists": True,
                "last_object": serializer.data,
            }, status=status.HTTP_200_OK)
        else:
            return Response(data={
                "exists": False,
                "last_object": None,
            }, status=status.HTTP_200_OK)


class MyStatsView(APIView):
    permission_classes = [IsAuthenticated]

    @staticmethod
    def get(request):
        stats = {}
        objects = UserObjectExploration.objects.filter(user=request.user)
        stats["total"] = len(objects)
        for exploration in objects:
            category = exploration.geo_object.category
            if category not in stats:
                stats[category] = 0
            stats[category] += 1

        return Response(data=stats, status=status.HTTP_200_OK)


class SearchObjectsView(APIView):
    permission_classes = [AllowAny]
    serializer_class = SearchRequestSerializer

    @staticmethod
    def _compare(search_request: str, name_en: str, name_ru: str):
        search_request = search_request.lower()
        name_en = name_en.lower()
        name_ru = name_ru.lower()
        return max(fuzz.WRatio(search_request, name_en), fuzz.WRatio(search_request, name_ru))

    def post(self, request):
        request_serializer = SearchRequestSerializer(data=request.data)
        if request_serializer.is_valid():
            request_string = request_serializer.data.get("search_query")
        else:
            return Response(request_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        queryset = list(GeoObject.objects.all())
        for i, geo_object in enumerate(queryset):
            queryset[i] = {
                "object": geo_object,
                "score": self._compare(request_string, geo_object.name_ru, geo_object.name_en),
            }
        result = list(filter(lambda x: x["score"] >= GEO_OBJECTS_SEARCH_SIMILARITY, queryset))
        result.sort(key=lambda x: x["score"], reverse=True)
        result = result[:GEO_OBJECTS_SEARCH_MAX_RESULTS]

        result_data = []
        for item in result:
            item_data = {
                "object": GeoObjectSerializer(item["object"], context={"request": request}).data,
                "score": item["score"],
            }
            result_data.append(item_data)

        response = {
            "status": "ok",
            "search query": request_string,
            "count": len(result_data),
            "results": result_data,
        }

        return Response(data=response, status=status.HTTP_200_OK)


class APIRootView(APIView):
    @staticmethod
    def get(request):
        endpoints = {
            'get nearby objects': reverse('get_nearby', request=request),
            'check nearby object notification': reverse('check_nearby_notification', request=request),
            'my explorations': reverse('my_explorations', request=request),
            'last_exploration': reverse('last_exploration', request=request),
            'my_stats': reverse('my_stats', request=request),
            'search objects by name': reverse('geoobjects-search', request=request),
            'geo object list': request.build_absolute_uri('geo_object-list'),
            'submitted geo object list': request.build_absolute_uri('submitted_geo_objects'),
        }
        return Response(data=endpoints, status=status.HTTP_200_OK)
